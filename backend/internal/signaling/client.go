package signaling

import (
	"log"
	"time"

	"github.com/gorilla/websocket"
)

const (
	// pongWait/pingPeriod dùng cơ chế ping/pong chuẩn của gorilla/websocket
	// để phát hiện disconnect (mạng rớt đột ngột không gửi được close frame).
	pongWait   = 60 * time.Second
	pingPeriod = (pongWait * 9) / 10
	writeWait  = 10 * time.Second

	sendBufferSize = 16
)

// Client bọc 1 WebSocket connection persistent của 1 user — mỗi user chỉ
// giữ 1 connection tại một thời điểm trên instance hiện tại.
type Client struct {
	hub    *Hub
	userID string
	conn   *websocket.Conn
	send   chan []byte
}

func newClient(hub *Hub, userID string, conn *websocket.Conn) *Client {
	return &Client{
		hub:    hub,
		userID: userID,
		conn:   conn,
		send:   make(chan []byte, sendBufferSize),
	}
}

// readPump đọc message từ Client, forward vào Hub xử lý routing. Dừng và
// dọn dẹp (unregister) khi connection lỗi/đóng.
func (c *Client) readPump() {
	defer c.hub.unregister(c)

	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})

	for {
		_, raw, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				log.Printf("signaling: user %s đóng kết nối bất thường: %v", c.userID, err)
			}
			return
		}
		c.hub.handleRaw(c, raw)
	}
}

// writePump là goroutine duy nhất được phép ghi vào conn (yêu cầu bắt
// buộc của gorilla/websocket — không ghi đồng thời từ nhiều goroutine).
// Nhận message từ Hub (routing trực tiếp) lẫn từ Redis Pub/Sub (cross-instance).
func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case msg, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
				return
			}
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
