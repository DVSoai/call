package calls

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	ringingTTL   = 30 * time.Second
	connectedTTL = 6 * time.Hour
)

// StatusRinging/StatusConnected là 2 trạng thái tạm thời của 1 room trong
// Redis — khác với status bền vững ở call_history (missed/rejected/completed).
const (
	StatusRinging   = "ringing"
	StatusConnected = "connected"
)

// RoomState đại diện 1 room đang diễn ra (RINGING hoặc CONNECTED). Thiết kế
// theo participants []string ngay từ đầu (room-ready) — call 1-1 luôn có
// đúng 2 phần tử, Group Call sau này chỉ cần thêm participant vào slice
// này, không cần đổi cấu trúc dữ liệu.
// ModeDirect/ModeGroup phân biệt call 1-1 (P2P, Server chỉ forward SDP) với
// Group Call (SFU, Server thật sự tham gia media) — xem docs/CALL_SYSTEM.md
// §7. Cùng convention đặt tên với Conversation.Type ("direct"/"group") đã
// dùng cho messaging.
const (
	ModeDirect = "direct"
	ModeGroup  = "group"
)

type RoomState struct {
	RoomID       string    `json:"roomId"`
	CallType     string    `json:"callType"` // "audio" | "video"
	Status       string    `json:"status"`   // StatusRinging | StatusConnected
	CreatedBy    string    `json:"createdBy"`
	Participants []string  `json:"participants"`
	CreatedAt    time.Time `json:"createdAt"`

	// Mode mặc định "" tương đương ModeDirect (room cũ/1-1 không set field
	// này) — chỉ ModeGroup mới route qua internal/sfu, mọi thứ khác giữ
	// nguyên hành vi cũ.
	Mode string `json:"mode,omitempty"`

	// OfferSDP lưu lại offer gốc — cần thiết để redeliver cho callee lúc
	// reconnect sau khi bị đánh thức qua Push (app background/bị kill),
	// vì offer chỉ được forward sống 1 lần lúc gọi tới (xem §5.2 CALL_SYSTEM.md).
	// Không dùng cho ModeGroup (SFU tự renegotiate lại khi callee reconnect,
	// không cần redeliver offer cũ).
	OfferSDP string `json:"offerSdp,omitempty"`

	// ConversationID — chỉ ModeGroup dùng, trỏ tới conversation nhắn tin
	// (group chat) đã tạo ra cuộc gọi này. Dùng để tra "conversation X đang
	// có cuộc gọi nhóm sống không" (SetActiveGroupCall/GetActiveGroupCall)
	// — bấm "Gọi nhóm" lần 2 cho cùng 1 group phải JOIN LẠI room đang có,
	// không tạo room mới đè lên.
	ConversationID string `json:"conversationId,omitempty"`
}

// IsGroup trả về true nếu room này là Group Call (SFU) — helper tránh so
// sánh string rải rác khắp handlers.go.
func (r RoomState) IsGroup() bool { return r.Mode == ModeGroup }

func roomKey(roomID string) string {
	return "call:" + roomID
}

// CreateRinging khởi tạo room ở trạng thái RINGING, TTL 30s — nếu không ai
// trả lời trong 30s, key tự hết hạn, coi như missed call (không cần cron
// dọn dẹp). Dùng SetNX để tránh race nếu 2 message offer trùng roomId.
func (s *Store) CreateRinging(ctx context.Context, room RoomState) error {
	room.Status = StatusRinging
	data, err := json.Marshal(room)
	if err != nil {
		return fmt.Errorf("calls: marshal room: %w", err)
	}
	ok, err := s.rdb.SetNX(ctx, roomKey(room.RoomID), data, ringingTTL).Result()
	if err != nil {
		return fmt.Errorf("calls: CreateRinging: %w", err)
	}
	if !ok {
		return fmt.Errorf("calls: room %s đã tồn tại", room.RoomID)
	}
	return nil
}

// Get trả về room state hiện tại, hoặc (nil, nil) nếu room không tồn tại
// (đã kết thúc hoặc TTL RINGING hết hạn).
func (s *Store) Get(ctx context.Context, roomID string) (*RoomState, error) {
	data, err := s.rdb.Get(ctx, roomKey(roomID)).Bytes()
	if errors.Is(err, redis.Nil) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("calls: Get room: %w", err)
	}
	var room RoomState
	if err := json.Unmarshal(data, &room); err != nil {
		return nil, fmt.Errorf("calls: unmarshal room: %w", err)
	}
	return &room, nil
}

// MarkConnected chuyển room sang CONNECTED khi callee accept (gửi answer).
// TTL nới ra 6 giờ chỉ để làm safety net phòng message call-end bị mất —
// bình thường room bị xoá tường minh qua Delete() khi nhận call-end.
func (s *Store) MarkConnected(ctx context.Context, roomID string) error {
	room, err := s.Get(ctx, roomID)
	if err != nil {
		return err
	}
	if room == nil {
		return fmt.Errorf("calls: MarkConnected: room %s không tồn tại (có thể đã hết hạn RINGING)", roomID)
	}
	room.Status = StatusConnected
	data, err := json.Marshal(room)
	if err != nil {
		return fmt.Errorf("calls: marshal room: %w", err)
	}
	if err := s.rdb.Set(ctx, roomKey(roomID), data, connectedTTL).Err(); err != nil {
		return fmt.Errorf("calls: MarkConnected: %w", err)
	}
	return nil
}

// Delete kết thúc room tường minh — gọi khi Hub nhận message call-end
// hoặc call-reject.
func (s *Store) Delete(ctx context.Context, roomID string) error {
	if err := s.rdb.Del(ctx, roomKey(roomID)).Err(); err != nil {
		return fmt.Errorf("calls: Delete room: %w", err)
	}
	return nil
}

// ExtendGroupRoom gia hạn TTL room Group Call lên connectedTTL (6 giờ) —
// gọi mỗi khi có người join SFU. Khác 1-1 (chỉ MarkConnected 1 lần lúc
// callee duy nhất trả lời), Group Call có thể có người join muộn SAU KHI
// room đã tồn tại quá ringingTTL (30s) — nếu không gia hạn, room (và cuộc
// gọi đang diễn ra) sẽ tự "biến mất" khỏi Redis dù vẫn đang có người nói
// chuyện (SFU sống độc lập trong bộ nhớ, không phụ thuộc Redis, nhưng
// GetActiveGroupCall/redeliverPendingOffer thì có). Đồng thời gia hạn luôn
// mapping active_group_call nếu room có ConversationID.
func (s *Store) ExtendGroupRoom(ctx context.Context, roomID string) error {
	room, err := s.Get(ctx, roomID)
	if err != nil {
		return err
	}
	if room == nil {
		return fmt.Errorf("calls: ExtendGroupRoom: room %s không tồn tại", roomID)
	}
	room.Status = StatusConnected
	data, err := json.Marshal(room)
	if err != nil {
		return fmt.Errorf("calls: marshal room: %w", err)
	}
	if err := s.rdb.Set(ctx, roomKey(roomID), data, connectedTTL).Err(); err != nil {
		return fmt.Errorf("calls: ExtendGroupRoom: %w", err)
	}
	if room.ConversationID != "" {
		if err := s.SetActiveGroupCall(ctx, room.ConversationID, roomID); err != nil {
			return fmt.Errorf("calls: ExtendGroupRoom: refresh active mapping: %w", err)
		}
	}
	return nil
}

func activeGroupCallKey(conversationID string) string {
	return "active_group_call:" + conversationID
}

// SetActiveGroupCall đánh dấu conversation X đang có 1 Group Call sống ở
// room nào — TTL connectedTTL, tự gia hạn mỗi khi có người join
// (ExtendGroupRoom). Dùng để "Gọi nhóm" lần 2 cho cùng conversation JOIN
// LẠI thay vì tạo room mới.
func (s *Store) SetActiveGroupCall(ctx context.Context, conversationID, roomID string) error {
	if err := s.rdb.Set(ctx, activeGroupCallKey(conversationID), roomID, connectedTTL).Err(); err != nil {
		return fmt.Errorf("calls: SetActiveGroupCall: %w", err)
	}
	return nil
}

// GetActiveGroupCall trả về roomID đang sống cho conversation này, hoặc ""
// nếu không có cuộc gọi nhóm nào đang diễn ra.
func (s *Store) GetActiveGroupCall(ctx context.Context, conversationID string) (string, error) {
	roomID, err := s.rdb.Get(ctx, activeGroupCallKey(conversationID)).Result()
	if errors.Is(err, redis.Nil) {
		return "", nil
	}
	if err != nil {
		return "", fmt.Errorf("calls: GetActiveGroupCall: %w", err)
	}
	return roomID, nil
}

// ClearActiveGroupCall xoá đánh dấu — gọi khi Group Call thực sự kết thúc
// (room rỗng, người cuối cùng đã rời).
func (s *Store) ClearActiveGroupCall(ctx context.Context, conversationID string) error {
	if err := s.rdb.Del(ctx, activeGroupCallKey(conversationID)).Err(); err != nil {
		return fmt.Errorf("calls: ClearActiveGroupCall: %w", err)
	}
	return nil
}

func pendingOfferKey(calleeUserID string) string {
	return "pending_offer:" + calleeUserID
}

// SetPendingOffer đánh dấu callee đang có 1 offer RINGING chờ redeliver khi
// họ reconnect (sau khi bị đánh thức qua Push) — TTL khớp ringingTTL, tự
// hết hạn cùng lúc room RINGING hết hạn, không cần dọn riêng.
func (s *Store) SetPendingOffer(ctx context.Context, calleeUserID, roomID string) error {
	if err := s.rdb.Set(ctx, pendingOfferKey(calleeUserID), roomID, ringingTTL).Err(); err != nil {
		return fmt.Errorf("calls: SetPendingOffer: %w", err)
	}
	return nil
}

// GetPendingOffer trả về roomID đang RINGING chờ callee này, hoặc "" nếu
// không có (bình thường — đa số user connect không phải để nhận cuộc gọi).
func (s *Store) GetPendingOffer(ctx context.Context, calleeUserID string) (string, error) {
	roomID, err := s.rdb.Get(ctx, pendingOfferKey(calleeUserID)).Result()
	if errors.Is(err, redis.Nil) {
		return "", nil
	}
	if err != nil {
		return "", fmt.Errorf("calls: GetPendingOffer: %w", err)
	}
	return roomID, nil
}

// ClearPendingOffer xoá đánh dấu — gọi khi room kết thúc dưới mọi hình thức
// (answer/reject/end) để tránh redeliver offer đã không còn hiệu lực.
func (s *Store) ClearPendingOffer(ctx context.Context, calleeUserID string) error {
	if err := s.rdb.Del(ctx, pendingOfferKey(calleeUserID)).Err(); err != nil {
		return fmt.Errorf("calls: ClearPendingOffer: %w", err)
	}
	return nil
}
