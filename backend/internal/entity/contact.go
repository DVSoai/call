package entity

import "time"

const (
	ContactStatusPending  = "pending"
	ContactStatusAccepted = "accepted"
	ContactStatusRejected = "rejected"
	ContactStatusBlocked  = "blocked"
)

// Contact map bảng contacts. UserLow/UserHigh chỉ phục vụ unique index
// chống trùng cặp quan hệ (xem db.orderPair trong contact_repo.go) —
// không dùng ở tầng API/service, nhưng vẫn để exported cho đơn giản
// (GORM cần field xuất khỏi struct để quản lý cột).
type Contact struct {
	ID          string `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	RequesterID string `gorm:"type:uuid;not null;index"`
	AddresseeID string `gorm:"type:uuid;not null;index"`
	UserLow     string `gorm:"type:uuid;not null;uniqueIndex:idx_contacts_pair"`
	UserHigh    string `gorm:"type:uuid;not null;uniqueIndex:idx_contacts_pair"`
	Status      string `gorm:"not null;index"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func (Contact) TableName() string { return "contacts" }

// ContactWithUser gộp thêm thông tin cơ bản của "người kia" trong quan hệ
// — tiện cho danh sách contacts/lời mời mà không cần Client tự JOIN thêm.
// Không phải GORM model (không có TableName) — chỉ dùng làm kết quả Scan
// thủ công cho query JOIN trong contact_repo.listByStatus.
type ContactWithUser struct {
	Contact
	OtherUserID          string
	OtherUserPhone       string
	OtherUserDisplayName string
}
