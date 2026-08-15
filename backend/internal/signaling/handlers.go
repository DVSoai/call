package signaling

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"

	"callserver/internal/calls"
	"callserver/internal/entity"
	"callserver/internal/push"
)

// messageOpTimeout bao trọn cả chuỗi xử lý 1 message (Redis + Postgres +
// push dispatch cho trường hợp offer) — rộng hơn redisOpTimeout dùng cho
// register/unregister vì handleOffer có thể chạm cả 3 dependency.
const messageOpTimeout = 5 * time.Second

// handleRaw parse raw JSON từ Client thành Message rồi định tuyến theo Type.
func (h *Hub) handleRaw(c *Client, raw []byte) {
	var m Message
	if err := json.Unmarshal(raw, &m); err != nil {
		log.Printf("signaling: message JSON không hợp lệ từ user %s: %v", c.userID, err)
		return
	}
	// Không tin field "from" Client tự gửi lên — luôn override bằng danh
	// tính đã xác thực qua JWT lúc upgrade WebSocket, chống giả mạo.
	m.From = c.userID

	ctx, cancel := context.WithTimeout(context.Background(), messageOpTimeout)
	defer cancel()

	switch m.Type {
	case TypeOffer:
		h.handleOffer(ctx, c, m)
	case TypeAnswer:
		h.handleAnswer(ctx, m)
	case TypeICECandidate:
		h.handleICECandidate(ctx, m)
	case TypeCallEnd:
		h.handleCallEnd(ctx, m)
	case TypeCallReject:
		h.handleCallReject(ctx, m)
	case TypeChatMessage:
		h.handleChatMessage(ctx, c, m)
	default:
		log.Printf("signaling: message type không xác định %q từ user %s", m.Type, c.userID)
	}
}

// handleOffer khởi tạo room RINGING (Redis) rồi route offer tới callee —
// nếu callee offline (không có WebSocket sống ở bất kỳ instance nào),
// trigger push để đánh thức Client (§4.3 CALL_SYSTEM.md).
func (h *Hub) handleOffer(ctx context.Context, c *Client, m Message) {
	roomID := m.CallID
	if roomID == "" {
		roomID = uuid.NewString()
		m.CallID = roomID
	}
	callType := m.Payload.CallType
	if callType == "" {
		callType = "audio"
	}

	// Callee đã có 1 lời mời khác đang chờ trả lời (chưa answer/reject/end)
	// — coi như bận, trả reject ngay cho caller mới thay vì chồng thêm 1
	// room/CallKit UI thứ 2 (ghi đè pending_offer cũ sẽ làm "mất" lời mời
	// đầu — nghiêm trọng nhất khi callee đang offline, không có Client nào
	// sống để tự reject giúp như trường hợp online, xem CallBloc._handleIncomingOffer).
	if existingRoomID, err := h.store.GetPendingOffer(ctx, m.To); err != nil {
		log.Printf("signaling: GetPendingOffer lỗi cho user %s: %v", m.To, err)
	} else if existingRoomID != "" {
		h.forward(ctx, Message{Type: TypeCallReject, From: m.To, To: c.userID, CallID: roomID})
		return
	}

	room := calls.RoomState{
		RoomID:       roomID,
		CallType:     callType,
		CreatedBy:    c.userID,
		Participants: []string{c.userID, m.To},
		CreatedAt:    time.Now(),
		OfferSDP:     m.Payload.SDP,
	}
	if err := h.store.CreateRinging(ctx, room); err != nil {
		log.Printf("signaling: CreateRinging lỗi cho room %s: %v", roomID, err)
	}
	// Đánh dấu callee có offer đang chờ — dùng để redeliver nếu họ reconnect
	// sau khi bị đánh thức qua Push (app background/bị kill), vì offer bên
	// dưới chỉ forward sống 1 lần (xem register() trong hub.go).
	if err := h.store.SetPendingOffer(ctx, m.To, roomID); err != nil {
		log.Printf("signaling: SetPendingOffer lỗi cho room %s: %v", roomID, err)
	}

	h.enrichPreferredLanguage(ctx, &m)

	raw, err := json.Marshal(m)
	if err != nil {
		log.Printf("signaling: marshal offer lỗi: %v", err)
		return
	}

	if h.route(ctx, m.To, raw) {
		return
	}
	h.dispatchInvitePush(ctx, m, callType)
}

func (h *Hub) dispatchInvitePush(ctx context.Context, m Message, callType string) {
	h.invitePush(ctx, m.From, m.To, m.CallID, callType)
}

// invitePush gửi push đánh thức 1 callee cụ thể — tách riêng khỏi
// dispatchInvitePush (1-1, đúng 1 callee) để InviteGroupParticipants (group,
// N người) dùng lại được, không lặp code.
func (h *Hub) invitePush(ctx context.Context, callerID, calleeID, roomID, callType string) {
	caller, err := h.users.GetByID(ctx, callerID)
	if err != nil {
		log.Printf("signaling: lấy thông tin caller %s lỗi: %v", callerID, err)
		return
	}
	tokens, err := h.devices.TokensForUser(ctx, calleeID)
	if err != nil {
		log.Printf("signaling: lấy device token của %s lỗi: %v", calleeID, err)
		return
	}
	if len(tokens) == 0 {
		log.Printf("signaling: user %s offline và không có device token để push", calleeID)
		return
	}
	callerName := callerID
	if caller != nil && caller.DisplayName != "" {
		callerName = caller.DisplayName
	}
	invite := push.CallInvite{
		RoomID:       roomID,
		CallerID:     callerID,
		CallerName:   callerName,
		CallType:     callType,
		DeviceTokens: tokens,
	}
	if err := h.push.SendCallInvite(ctx, invite); err != nil {
		log.Printf("signaling: gửi push cho room %s lỗi: %v", roomID, err)
	}
}

// enrichPreferredLanguage điền Payload.PreferredLanguage của người GỬI
// (m.From) trước khi forward offer/answer cho call 1-1 — Translated Call
// (docs/CALL_SYSTEM.md §8) cần phía nghe biết chính xác ngôn ngữ người kia
// đang nói để ép cứng vào ASR, thay vì để Whisper tự đoán (dễ đoán sai với
// đoạn audio ngắn). Server tự tra DB thay vì tin Client tự gửi field này —
// tránh trường hợp Client gửi giá trị cũ/sai.
func (h *Hub) enrichPreferredLanguage(ctx context.Context, m *Message) {
	sender, err := h.users.GetByID(ctx, m.From)
	if err != nil {
		log.Printf("signaling: lấy preferredLanguage của %s lỗi: %v", m.From, err)
		return
	}
	if sender != nil {
		m.Payload.PreferredLanguage = sender.PreferredLanguage
	}
}

// CreateGroupCall tạo 1 room Mode=group RINGING rồi mời toàn bộ
// participantIds — dùng bởi REST handler POST /calls/group. Trả về roomID
// để Client biết room nào để gọi tiếp POST /calls/:roomId/join lúc Accept.
//
// Nếu conversationID đã có 1 Group Call đang sống (bấm "Gọi nhóm" lần 2 cho
// cùng group trong lúc cuộc gọi vẫn diễn ra — vd. vừa rời rồi bấm gọi lại)
// — trả về ĐÚNG roomID đang có, KHÔNG tạo room mới/mời lại (người rồi
// join lại chỉ cần POST /calls/:roomId/join là đủ, không cần "lời mời"
// nữa vì họ chính là người chủ động gọi lại).
func (h *Hub) CreateGroupCall(ctx context.Context, creatorID, conversationID string, participantIDs []string, callType string) (string, error) {
	if conversationID != "" {
		if existingRoomID, err := h.store.GetActiveGroupCall(ctx, conversationID); err != nil {
			log.Printf("signaling: GetActiveGroupCall lỗi cho conversation %s: %v", conversationID, err)
		} else if existingRoomID != "" {
			if room, err := h.store.Get(ctx, existingRoomID); err != nil {
				log.Printf("signaling: đọc room %s lỗi: %v", existingRoomID, err)
			} else if room != nil {
				return existingRoomID, nil
			}
		}
	}

	if callType == "" {
		callType = "audio"
	}
	roomID := uuid.NewString()
	room := calls.RoomState{
		RoomID:         roomID,
		CallType:       callType,
		Mode:           calls.ModeGroup,
		CreatedBy:      creatorID,
		Participants:   append([]string{creatorID}, participantIDs...),
		CreatedAt:      time.Now(),
		ConversationID: conversationID,
	}
	if err := h.store.CreateRinging(ctx, room); err != nil {
		return "", fmt.Errorf("signaling: CreateGroupCall: %w", err)
	}
	if conversationID != "" {
		if err := h.store.SetActiveGroupCall(ctx, conversationID, roomID); err != nil {
			log.Printf("signaling: SetActiveGroupCall lỗi cho conversation %s: %v", conversationID, err)
		}
	}
	h.InviteGroupParticipants(ctx, room, creatorID)
	return roomID, nil
}

// InviteGroupParticipants mời từng participant vào 1 group room — dùng bởi
// REST handler POST /calls/group. Lời mời chưa có SDP (group chưa có gì để
// offer tới khi chưa ai join SFU) — Payload.Mode="group" để Client phân
// biệt với offer 1-1 thật, chỉ hiện Incoming UI, KHÔNG dùng làm
// pendingRemoteOfferSdp (xem CallBloc._handleIncomingOffer).
func (h *Hub) InviteGroupParticipants(ctx context.Context, room calls.RoomState, callerID string) {
	for _, uid := range room.Participants {
		if uid == callerID {
			continue
		}
		m := Message{
			Type:   TypeOffer,
			From:   callerID,
			To:     uid,
			CallID: room.RoomID,
			Payload: Payload{
				CallType: room.CallType,
				Mode:     calls.ModeGroup,
			},
		}
		raw, err := json.Marshal(m)
		if err != nil {
			log.Printf("signaling: marshal group invite lỗi: %v", err)
			continue
		}
		if h.route(ctx, uid, raw) {
			continue
		}
		h.invitePush(ctx, callerID, uid, room.RoomID, room.CallType)
	}
}

// handleAnswer: 2 nhánh tuỳ Mode của room.
//   - ModeGroup: answer này là trả lời cho offer SFU gửi xuống (đầu tiên
//     hoặc renegotiate) — áp vào đúng Peer của user đó trong internal/sfu,
//     KHÔNG forward đi đâu (chỉ có 2 bên Client<->Server, không có "phía
//     kia" để forward tới).
//   - Mặc định (ModeDirect, luồng 1-1 cũ): giữ nguyên y hệt — chuyển room
//     sang CONNECTED rồi forward answer tới caller.
func (h *Hub) handleAnswer(ctx context.Context, m Message) {
	room, err := h.store.Get(ctx, m.CallID)
	if err != nil {
		log.Printf("signaling: đọc room %s lỗi lúc handleAnswer: %v", m.CallID, err)
	}
	if room != nil && room.IsGroup() {
		if err := h.sfuManager.SetAnswer(m.CallID, m.From, m.Payload.SDP); err != nil {
			log.Printf("signaling: sfu SetAnswer lỗi cho user %s room %s: %v", m.From, m.CallID, err)
		}
		return
	}

	// m.From là callee (người vừa answer) — offer không còn cần redeliver nữa.
	if err := h.store.ClearPendingOffer(ctx, m.From); err != nil {
		log.Printf("signaling: ClearPendingOffer lỗi cho user %s: %v", m.From, err)
	}
	if err := h.store.MarkConnected(ctx, m.CallID); err != nil {
		log.Printf("signaling: MarkConnected lỗi cho room %s: %v", m.CallID, err)
	}
	h.enrichPreferredLanguage(ctx, &m)
	h.forward(ctx, m)
}

// handleICECandidate: ModeGroup áp thẳng vào Peer trong internal/sfu (2 bên
// Client<->Server, không có "phía kia" để forward); mặc định (1-1) giữ
// nguyên hành vi cũ — chỉ forward, không chạm state.
func (h *Hub) handleICECandidate(ctx context.Context, m Message) {
	room, err := h.store.Get(ctx, m.CallID)
	if err != nil {
		log.Printf("signaling: đọc room %s lỗi lúc handleICECandidate: %v", m.CallID, err)
	}
	if room != nil && room.IsGroup() {
		var candidate map[string]any
		if err := json.Unmarshal(m.Payload.Candidate, &candidate); err != nil {
			log.Printf("signaling: parse ice candidate (group) lỗi: %v", err)
			return
		}
		if err := h.sfuManager.AddICECandidate(m.CallID, m.From, candidate); err != nil {
			log.Printf("signaling: sfu AddICECandidate lỗi cho user %s room %s: %v", m.From, m.CallID, err)
		}
		return
	}
	h.forward(ctx, m)
}

// handleCallEnd: ModeGroup nghĩa là 1 người RỜI group room (không phải kết
// thúc cho tất cả) — chỉ gỡ đúng Peer đó khỏi SFU, room vẫn sống cho những
// người còn lại. Mặc định (1-1) giữ nguyên: đóng room, ghi call_history,
// forward cho phía còn lại.
func (h *Hub) handleCallEnd(ctx context.Context, m Message) {
	room, err := h.store.Get(ctx, m.CallID)
	if err != nil {
		log.Printf("signaling: đọc room %s lỗi lúc handleCallEnd: %v", m.CallID, err)
	}
	if room != nil && room.IsGroup() {
		if h.sfuManager.Leave(m.CallID, m.From) {
			h.clearGroupRoom(ctx, m.CallID)
		}
		return
	}
	h.finalizeRoom(ctx, m.CallID, entity.StatusCompleted)
	h.forward(ctx, m)
}

// handleCallReject: ModeGroup nghĩa là 1 invitee từ chối lời mời TRƯỚC KHI
// join SFU (chưa có Peer nào để gỡ) — không kết thúc room, những người khác
// vẫn tham gia được bình thường. Mặc định (1-1) giữ nguyên: đóng room, ghi
// call_history rejected, forward cho caller.
func (h *Hub) handleCallReject(ctx context.Context, m Message) {
	room, err := h.store.Get(ctx, m.CallID)
	if err != nil {
		log.Printf("signaling: đọc room %s lỗi lúc handleCallReject: %v", m.CallID, err)
	}
	if room != nil && room.IsGroup() {
		return
	}
	h.finalizeRoom(ctx, m.CallID, entity.StatusRejected)
	h.forward(ctx, m)
}

// RejectCall là fallback REST cho reject khi Client không có WS sống để tự
// gửi call-reject message — xảy ra khi app bị kill hẳn và user bấm Decline
// ngay trên màn hình cuộc gọi đến kiểu native (CallKit), lúc đó quyết định
// đến từ code native ngoài Flutter engine, không có WebSocket để gửi qua
// (xem android/.../CallRejectNativeHandler.kt). Logic giống hệt
// handleCallReject, chỉ khác nguồn gọi (REST thay vì WS message).
func (h *Hub) RejectCall(ctx context.Context, roomID, fromUserID string) error {
	room, err := h.store.Get(ctx, roomID)
	if err != nil {
		return err
	}
	if room == nil {
		// Room đã hết hạn/kết thúc từ trước (vd. caller đã tự huỷ) — không
		// còn gì để reject, không phải lỗi.
		return nil
	}
	m := Message{Type: TypeCallReject, From: fromUserID, CallID: roomID}
	for _, uid := range room.Participants {
		if uid != fromUserID {
			m.To = uid
		}
	}
	h.finalizeRoom(ctx, roomID, entity.StatusRejected)
	h.forward(ctx, m)
	return nil
}

// finalizeRoom đọc room state trước khi xoá (để lấy participants/callType/
// thời điểm bắt đầu), rồi ghi 1 dòng bền vững vào PostgreSQL. Nếu room đã
// hết hạn TTL RINGING trước khi Client gửi call-end/call-reject, room sẽ
// là nil — coi như missed call, không có gì để ghi thêm (đã tự "biến mất"
// theo đúng thiết kế TTL, không cần cron dọn dẹp).
func (h *Hub) finalizeRoom(ctx context.Context, roomID, status string) {
	room, err := h.store.Get(ctx, roomID)
	if err != nil {
		log.Printf("signaling: đọc room %s trước khi kết thúc lỗi: %v", roomID, err)
	}
	if err := h.store.Delete(ctx, roomID); err != nil {
		log.Printf("signaling: xoá room %s lỗi: %v", roomID, err)
	}
	if room == nil {
		return
	}
	// Dọn pending_offer cho toàn bộ participants — DEL trên key không tồn
	// tại vô hại, đơn giản hơn việc phải biết chính xác ai là callee.
	for _, uid := range room.Participants {
		if err := h.store.ClearPendingOffer(ctx, uid); err != nil {
			log.Printf("signaling: ClearPendingOffer lỗi cho user %s: %v", uid, err)
		}
	}

	// call-end tới lúc room vẫn đang RINGING (chưa ai answer, kể cả do
	// caller tự huỷ hoặc do Client tự huỷ lúc hết 30s không ai bắt máy) —
	// đây là "missed", không phải "completed" (status đó chỉ có ý nghĩa cho
	// cuộc gọi đã thực sự kết nối).
	if status == entity.StatusCompleted && room.Status == calls.StatusRinging {
		status = entity.StatusMissed
	}

	now := time.Now()
	entry := entity.CallHistoryEntry{
		RoomID:       room.RoomID,
		CreatedBy:    room.CreatedBy,
		CallType:     room.CallType,
		Status:       status,
		StartedAt:    room.CreatedAt,
		EndedAt:      &now,
		Participants: room.Participants,
	}
	if err := h.history.Insert(ctx, entry); err != nil {
		log.Printf("signaling: ghi call_history cho room %s lỗi: %v", roomID, err)
	}
}

// forward marshal lại message (đã override From) rồi route tới "To".
func (h *Hub) forward(ctx context.Context, m Message) {
	raw, err := json.Marshal(m)
	if err != nil {
		log.Printf("signaling: marshal message lỗi: %v", err)
		return
	}
	h.route(ctx, m.To, raw)
}

// route thử giao local trước (cùng instance), sau đó tra presence để biết
// user đang ở instance nào và publish qua Redis Pub/Sub nếu khác instance
// hiện tại. Trả về false nếu user offline hoàn toàn.
func (h *Hub) route(ctx context.Context, toUserID string, raw []byte) bool {
	if h.deliverLocal(toUserID, raw) {
		return true
	}

	instanceID, online, err := h.store.InstanceOf(ctx, toUserID)
	if err != nil {
		log.Printf("signaling: tra presence của %s lỗi: %v", toUserID, err)
		return false
	}
	if !online || instanceID == h.instanceID {
		// online == false: user thực sự offline.
		// instanceID == h.instanceID: presence nói ở instance này nhưng
		// không có trong local map — dữ liệu stale, coi như offline.
		return false
	}

	if err := h.store.PublishToInstance(ctx, instanceID, raw); err != nil {
		log.Printf("signaling: publish sang instance %s lỗi: %v", instanceID, err)
		return false
	}
	return true
}
