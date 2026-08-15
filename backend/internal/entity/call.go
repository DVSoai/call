package entity

import "time"

// Trạng thái bền vững của 1 room trong call_history — khác với trạng thái
// tạm thời (ringing/connected) ở internal/calls.RoomState. Enforce ở tầng
// Go (không có CHECK constraint DB cho cột này khi dùng GORM — xem
// internal/db/migrate.go).
const (
	StatusMissed    = "missed"
	StatusRejected  = "rejected"
	StatusCompleted = "completed"
	StatusOngoing   = "ongoing"
)

// CallHistoryEntry đại diện 1 room/cuộc gọi. Participants KHÔNG phải cột
// (`gorm:"-"`) — populate riêng qua CallParticipant, xem call_history_repo.go.
// Với call 1-1, Participants luôn có đúng 2 phần tử; thiết kế room-ready
// để Group Call sau này chỉ cần thêm participant, không đổi struct.
type CallHistoryEntry struct {
	ID           string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	RoomID       string    `gorm:"column:room_id;type:uuid;uniqueIndex;not null"`
	CreatedBy    string    `gorm:"type:uuid;not null;index"`
	CallType     string    `gorm:"not null"` // "audio" | "video"
	Status       string    `gorm:"not null"` // "missed" | "rejected" | "completed" | "ongoing"
	StartedAt    time.Time `gorm:"not null"`
	EndedAt      *time.Time
	Participants []string `gorm:"-"` // userID tham gia room, JOIN từ call_participants
}

func (CallHistoryEntry) TableName() string { return "call_history" }

// CallParticipant map bảng call_participants — room_id trỏ tới
// CallHistoryEntry.RoomID (không phải ID), giữ nguyên thiết kế cũ.
type CallParticipant struct {
	ID       string `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	RoomID   string `gorm:"column:room_id;type:uuid;not null;uniqueIndex:idx_call_participants_unique"`
	UserID   string `gorm:"type:uuid;not null;index;uniqueIndex:idx_call_participants_unique"`
	JoinedAt *time.Time
	LeftAt   *time.Time
}

func (CallParticipant) TableName() string { return "call_participants" }
