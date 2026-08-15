package signaling

import (
	"context"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v4"

	"callserver/internal/calls"
	"callserver/internal/db"
	"callserver/internal/push"
	"callserver/internal/sfu"
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

	// sfuManager quản lý toàn bộ Group Call room (SFU, xem internal/sfu) —
	// call 1-1 (ModeDirect) không chạm vào field này.
	sfuManager *sfu.Manager

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
	sfuICEServers []webrtc.ICEServer,
) *Hub {
	h := &Hub{
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
	// Callback dùng lại route()/deliverLocal() đã có — sfu package không tự
	// gửi WS, chỉ báo lại "cần gửi offer/candidate này cho user X".
	h.sfuManager = sfu.NewManager(sfuICEServers, h.sendSFUOffer, h.sendSFUICECandidate)
	return h
}

// sendSFUOffer/sendSFUICECandidate là 2 callback truyền cho sfu.Manager lúc
// tạo — internal/sfu không biết gì về Message/WebSocket, chỉ gọi lại đây
// mỗi khi cần đẩy offer/ICE candidate mới xuống 1 user trong group room.
func (h *Hub) sendSFUOffer(ctx context.Context, roomID, userID, sdp string) {
	raw, err := json.Marshal(Message{
		Type: TypeOffer, From: "server", To: userID, CallID: roomID,
		Payload: Payload{SDP: sdp, Mode: calls.ModeGroup},
	})
	if err != nil {
		log.Printf("signaling: marshal sfu offer lỗi: %v", err)
		return
	}
	h.route(ctx, userID, raw)
}

func (h *Hub) sendSFUICECandidate(ctx context.Context, roomID, userID string, candidate map[string]any) {
	candidateJSON, err := json.Marshal(candidate)
	if err != nil {
		log.Printf("signaling: marshal sfu ice candidate lỗi: %v", err)
		return
	}
	raw, err := json.Marshal(Message{
		Type: TypeICECandidate, From: "server", To: userID, CallID: roomID,
		Payload: Payload{Candidate: candidateJSON, Mode: calls.ModeGroup},
	})
	if err != nil {
		log.Printf("signaling: marshal sfu ice candidate message lỗi: %v", err)
		return
	}
	h.route(ctx, userID, raw)
}

// JoinGroupCall tạo 1 SFU Peer cho user trong room — gọi từ REST handler
// POST /calls/:roomId/join (xem internal/api/handlers_calls.go).
func (h *Hub) JoinGroupCall(ctx context.Context, roomID, userID string) error {
	if err := h.sfuManager.Join(ctx, roomID, userID); err != nil {
		return err
	}
	// Gia hạn TTL room lên connectedTTL — nếu không, room (dù SFU vẫn đang
	// forward audio bình thường) sẽ tự hết hạn khỏi Redis sau 30s
	// (ringingTTL), làm GetActiveGroupCall/redeliverPendingOffer nhìn thấy
	// "không có cuộc gọi nào" dù thực ra vẫn đang diễn ra.
	if err := h.store.ExtendGroupRoom(ctx, roomID); err != nil {
		log.Printf("signaling: ExtendGroupRoom lỗi cho room %s: %v", roomID, err)
	}
	// Đánh dấu trên Client để unregister() dọn được SFU Peer nếu WS ngắt
	// giữa chừng — user phải đang có WS sống mới join được (REST handler
	// yêu cầu JWT hợp lệ nhưng không bắt buộc WS; nếu user gọi join REST
	// mà không có WS local trên instance này, bỏ qua bước đánh dấu, chấp
	// nhận dọn trễ qua PeerConnectionStateFailed).
	h.mu.Lock()
	if c, ok := h.clients[userID]; ok {
		c.groupRoomID = roomID
	}
	h.mu.Unlock()
	return nil
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
	groupRoomID := c.groupRoomID
	if stillCurrent {
		delete(h.clients, c.userID)
	}
	h.mu.Unlock()

	if !stillCurrent {
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), redisOpTimeout)
	defer cancel()

	// Dọn SFU Peer nếu user đang ở giữa 1 Group Call — không đợi ICE timeout
	// tự phát hiện PeerConnectionStateFailed (có độ trễ), disconnect WS là
	// tín hiệu chắc chắn hơn để dọn ngay.
	if groupRoomID != "" && h.sfuManager.Leave(groupRoomID, c.userID) {
		h.clearGroupRoom(ctx, groupRoomID)
	}

	if err := h.store.SetOffline(ctx, c.userID); err != nil {
		log.Printf("signaling: SetOffline lỗi cho user %s: %v", c.userID, err)
	}
}

// clearGroupRoom dọn RoomState + mapping active_group_call khi 1 Group Call
// thực sự kết thúc (người cuối cùng vừa rời) — gọi từ unregister() (WS
// ngắt) và handleCallEnd (rời chủ động).
func (h *Hub) clearGroupRoom(ctx context.Context, roomID string) {
	room, err := h.store.Get(ctx, roomID)
	if err != nil {
		log.Printf("signaling: đọc room %s trước khi dọn lỗi: %v", roomID, err)
	}
	if err := h.store.Delete(ctx, roomID); err != nil {
		log.Printf("signaling: xoá room %s lỗi: %v", roomID, err)
	}
	if room != nil && room.ConversationID != "" {
		if err := h.store.ClearActiveGroupCall(ctx, room.ConversationID); err != nil {
			log.Printf("signaling: ClearActiveGroupCall lỗi cho conversation %s: %v", room.ConversationID, err)
		}
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
