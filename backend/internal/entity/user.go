// Package entity chứa thuần struct GORM model (data shape + cột DB) —
// KHÔNG chứa logic (query nằm ở internal/db, business rule nằm ở
// internal/service). Đây là nơi DUY NHẤT cần sửa khi thêm/đổi cột DB.
package entity

import "time"

type User struct {
	ID                string `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	Phone             string `gorm:"uniqueIndex;not null"`
	DisplayName       string `gorm:"not null;default:''"`
	PreferredLanguage string `gorm:"not null;default:'vi'"`
	CreatedAt         time.Time
}

func (User) TableName() string { return "users" }

type DeviceToken struct {
	ID        string `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	UserID    string `gorm:"type:uuid;not null;index;uniqueIndex:idx_device_tokens_unique"`
	Platform  string `gorm:"not null;uniqueIndex:idx_device_tokens_unique"`
	PushToken string `gorm:"not null;uniqueIndex:idx_device_tokens_unique"`
	CreatedAt time.Time
}

func (DeviceToken) TableName() string { return "device_tokens" }
