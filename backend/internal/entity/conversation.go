package entity

import "time"

const (
	ConversationTypeDirect = "direct"
	ConversationTypeGroup  = "group"
)

const (
	ParticipantRoleOwner  = "owner"
	ParticipantRoleAdmin  = "admin"
	ParticipantRoleMember = "member"
)

const MessageTypeText = "text" // "image"/"file" dành cho giai đoạn sau

type Conversation struct {
	ID                 string `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	Type               string `gorm:"column:conversation_type;not null"`
	Name               *string
	CreatedBy          string `gorm:"type:uuid;not null;index"`
	CreatedAt          time.Time
	LastMessageAt      *time.Time
	LastMessagePreview *string

	// Participants KHÔNG phải cột — chỉ điền thủ công khi tạo mới để trả
	// về cho caller, dữ liệu thật nằm ở bảng conversation_participants.
	Participants []string `gorm:"-"`
}

func (Conversation) TableName() string { return "conversations" }

type ConversationParticipant struct {
	ID             string `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	ConversationID string `gorm:"type:uuid;not null;uniqueIndex:idx_conversation_participants_unique"`
	UserID         string `gorm:"type:uuid;not null;index;uniqueIndex:idx_conversation_participants_unique"`
	Role           string `gorm:"not null;default:member"`
	JoinedAt       time.Time
	LeftAt         *time.Time
}

func (ConversationParticipant) TableName() string { return "conversation_participants" }

// ParticipantSummary — kết quả JOIN conversation_participants + users cho
// 1 tập conversationIDs trong đúng 1 query (Scan thủ công, không phải GORM
// model) — dùng để trả participants trong API response mà không N+1 theo
// từng conversation (xem ConversationRepo.ListParticipantSummaries).
type ParticipantSummary struct {
	ConversationID string
	UserID         string
	Phone          string
	DisplayName    string
}

type Message struct {
	ID             string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	ConversationID string    `gorm:"type:uuid;not null;index:idx_messages_conversation"`
	SenderID       string    `gorm:"type:uuid;not null"`
	MessageType    string    `gorm:"not null;default:text"`
	Content        string    `gorm:"not null"`
	CreatedAt      time.Time `gorm:"index:idx_messages_conversation"`
}

func (Message) TableName() string { return "messages" }
