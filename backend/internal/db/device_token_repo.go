package db

import (
	"context"
	"fmt"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"callserver/internal/entity"
)

type DeviceTokenRepo struct {
	db *gorm.DB
}

func NewDeviceTokenRepo(gormDB *gorm.DB) *DeviceTokenRepo {
	return &DeviceTokenRepo{db: gormDB}
}

// RegisterToken lưu (hoặc bỏ qua nếu đã tồn tại) push token của 1 thiết bị.
func (r *DeviceTokenRepo) RegisterToken(ctx context.Context, userID, platform, pushToken string) error {
	token := entity.DeviceToken{UserID: userID, Platform: platform, PushToken: pushToken}
	err := r.db.WithContext(ctx).Clauses(clause.OnConflict{DoNothing: true}).Create(&token).Error
	if err != nil {
		return fmt.Errorf("device_token_repo: RegisterToken: %w", err)
	}
	return nil
}

// TokensForUser trả về toàn bộ push token đã đăng ký của 1 user, dùng khi
// cần đánh thức Client qua FCM/APNs vì không có WebSocket sống.
func (r *DeviceTokenRepo) TokensForUser(ctx context.Context, userID string) (map[string][]string, error) {
	var rows []entity.DeviceToken
	if err := r.db.WithContext(ctx).Where("user_id = ?", userID).Find(&rows).Error; err != nil {
		return nil, fmt.Errorf("device_token_repo: TokensForUser: %w", err)
	}

	tokens := make(map[string][]string)
	for _, row := range rows {
		tokens[row.Platform] = append(tokens[row.Platform], row.PushToken)
	}
	return tokens, nil
}
