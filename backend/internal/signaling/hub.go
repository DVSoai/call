package signaling

import (
	"context"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"

	"callserver/internal/calls"
	"callserver/internal/db"
	"callserver/internal/push"
)

// redisOpTimeout giới hạn thời gian chờ Redis/Postgres trong đường đi
// signaling — tránh 1 request WS treo vô hạn nếu dependency chậm/chết.
const redisOpTimeout = 3 * time.Second

// Hub là module trung tâm của Signaling — xem docs/CALL_SYSTEM.md §4.1.
// Giữ mapping userID -> Client (WebSocket) cho instance hiện tại, định
// tuyến message signaling, và phối hợp với calls.Store (Redis) + push.Dispatcher.
type Hub struct {
	mu      sync.RWMutex
	clients map[string]*Client

	store         *calls.Store
	users         *db.UserRepo
	devices       *db.DeviceTokenRepo
	history       *db.CallHistoryRepo
	conversations *db.ConversationRepo
	messages      *db.MessageRepo
	push          push.Dispatcher

	instanceID string
}

func NewHub(
	store *calls.Store,
	users *db.UserRepo,
	devices *db.DeviceTokenRepo,
	history *db.CallHistoryRepo,
	conversations *db.ConversationRepo,
	messages *db.MessageRepo,
	dispatcher push.Dispatcher,
	instanceID string,
) *Hub {
	return &Hub{
		clients:       make(map[string]*Client),
		store:         store,
		users:         users,
		devices:       devices,
		history:       history,
		conversations: conversations,
		messages:      messages,
		push:          dispatcher,
		instanceID:    instanceID,
	}
}

// Run subscribe channel Pub/Sub riêng của instance này, forward message
// nhận được (được publish từ instance khác) tới đúng Client local. Phải
// chạy trong 1 goroutine riêng suốt vòng đời server.
func (h *Hub) Run(ctx context.Context) {
	sub := h.store.SubscribeInstance(ctx, h.instanceID)
	defer sub.Close()

	ch := sub.Channel()
	for {
		select {
		case <-ctx.Done():
			return
		case msg, ok := <-ch:
			if !ok {
				return
			}
			var m Message
			if err := json.Unmarshal([]byte(msg.Payload), &m); err != nil {
				log.Printf("signaling: bỏ qua message pub/sub không hợp lệ: %v", err)
				continue
			}
			h.deliverLocal(m.To, []byte(msg.Payload))
		}
	}
}

// ServeWS upgrade HTTP connection thành WebSocket, đăng ký Client vào Hub
// và chạy read/write pump. Chặn (blocking) tới khi connection đóng.
func (h *Hub) ServeWS(conn *websocket.Conn, userID string) {
	client := newClient(h, userID, conn)
	h.register(client)

	go client.writePump()
	client.readPump() // blocking — chạy trên goroutine của HTTP handler
}

func (h *Hub) register(c *Client) {
	h.mu.Lock()
	// Mỗi user chỉ giữ 1 connection sống trên 1 instance — nếu đã có
	// connection cũ (vd. app mở lại kết nối mới trước khi cái cũ timeout),
	// đóng cái cũ để tránh leak goroutine/channel.
	if old, exists := h.clients[c.userID]; exists {
		close(old.send)
	}
	h.clients[c.userID] = c
	h.mu.Unlock()

	ctx, cancel := context.WithTimeout(context.Background(), redisOpTimeout)
	defer cancel()
	if err := h.store.SetOnline(ctx, c.userID, h.instanceID); err != nil {
		log.Printf("signaling: SetOnline lỗi cho user %s: %v", c.userID, err)
	}

	h.redeliverPendingOffer(ctx, c)
}

// redeliverPendingOffer forward lại offer RINGING (nếu có) ngay khi user vừa
// connect — bù cho trường hợp offer gốc đã forward sống trước đó nhưng user
// lúc ấy không có WS nào (app background/bị kill, được đánh thức qua Push
// rồi mới mở lại kết nối) — xem calls.Store.SetPendingOffer, §5.2 CALL_SYSTEM.md.
func (h *Hub) redeliverPendingOffer(ctx context.Context, c *Client) {
	roomID, err := h.store.GetPendingOffer(ctx, c.userID)
	if err != nil {
		log.Printf("signaling: GetPendingOffer lỗi cho user %s: %v", c.userID, err)
		return
	}
	if roomID == "" {
		return
	}
	room, err := h.store.Get(ctx, roomID)
	if err != nil {
		log.Printf("signaling: đọc room %s để redeliver offer lỗi: %v", roomID, err)
		return
	}
	if room == nil || room.Status != calls.StatusRinging {
		return
	}
	m := Message{
		Type:   TypeOffer,
		From:   room.CreatedBy,
		To:     c.userID,
		CallID: room.RoomID,
		Payload: Payload{
			SDP:      room.OfferSDP,
			CallType: room.CallType,
		},
	}
	raw, err := json.Marshal(m)
	if err != nil {
		log.Printf("signaling: marshal offer redeliver lỗi: %v", err)
		return
	}
	h.deliverLocal(c.userID, raw)
}

func (h *Hub) unregister(c *Client) {
	h.mu.Lock()
	// Chỉ xoá nếu đúng client này vẫn đang là connection hiện tại của user
	// — tránh trường hợp connection cũ unregister muộn, xoá nhầm connection
	// mới hơn vừa đăng ký.
	stillCurrent := h.clients[c.userID] == c
	if stillCurrent {
		delete(h.clients, c.userID)
	}
	h.mu.Unlock()

	if !stillCurrent {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), redisOpTimeout)
	defer cancel()
	if err := h.store.SetOffline(ctx, c.userID); err != nil {
		log.Printf("signaling: SetOffline lỗi cho user %s: %v", c.userID, err)
	}
}

// broadcastToParticipants gửi cùng nội dung message tới nhiều user — khác
// call (luôn đúng 1 "to"), chat-message có thể cần gửi tới N thành viên
// group. Set "to" riêng cho từng participant chỉ để route() biết định
// tuyến cross-instance đúng người (xem Run()) — Client không dùng field
// này để hiển thị chat.
func (h *Hub) broadcastToParticipants(ctx context.Context, participantIDs []string, m Message) {
	for _, uid := range participantIDs {
		m.To = uid
		raw, err := json.Marshal(m)
		if err != nil {
			log.Printf("signaling: marshal chat message lỗi: %v", err)
			return
		}
		h.route(ctx, uid, raw)
	}
}

// deliverLocal gửi raw message cho Client đang kết nối trên instance này,
// nếu có. Không lỗi nếu user không có mặt local (message bị bỏ qua).
func (h *Hub) deliverLocal(userID string, raw []byte) bool {
	h.mu.RLock()
	c, ok := h.clients[userID]
	h.mu.RUnlock()
	if !ok {
		return false
	}
	select {
	case c.send <- raw:
		return true
	default:
		log.Printf("signaling: send buffer đầy cho user %s, drop message", userID)
		return false
	}
}
