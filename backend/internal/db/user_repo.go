package db

import (
	"context"
	"errors"
	"fmt"

	"gorm.io/gorm"

	"callserver/internal/entity"
)

type UserRepo struct {
	db *gorm.DB
}

func NewUserRepo(gormDB *gorm.DB) *UserRepo {
	return &UserRepo{db: gormDB}
}

// GetOrCreateByPhone dùng cho POST /auth/dev-login: đăng nhập theo số điện
// thoại, tự tạo user mới nếu chưa tồn tại — chưa có OTP thật ở giai đoạn test.
func (r *UserRepo) GetOrCreateByPhone(ctx context.Context, phone string) (*entity.User, error) {
	u := entity.User{Phone: phone}
	if err := r.db.WithContext(ctx).Where(entity.User{Phone: phone}).FirstOrCreate(&u).Error; err != nil {
		return nil, fmt.Errorf("user_repo: GetOrCreateByPhone: %w", err)
	}
	return &u, nil
}

func (r *UserRepo) GetByID(ctx context.Context, userID string) (*entity.User, error) {
	var u entity.User
	err := r.db.WithContext(ctx).First(&u, "id = ?", userID).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("user_repo: GetByID: %w", err)
	}
	return &u, nil
}

// GetByPhone — dùng cho GET /users/search?phone=, tìm chính xác theo số
// điện thoại (không fuzzy search) để gửi lời mời kết bạn.
func (r *UserRepo) GetByPhone(ctx context.Context, phone string) (*entity.User, error) {
	var u entity.User
	err := r.db.WithContext(ctx).First(&u, "phone = ?", phone).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("user_repo: GetByPhone: %w", err)
	}
	return &u, nil
}

func (r *UserRepo) UpdatePreferredLanguage(ctx context.Context, userID, language string) error {
	tx := r.db.WithContext(ctx).Model(&entity.User{}).Where("id = ?", userID).Update("preferred_language", language)
	if tx.Error != nil {
		return fmt.Errorf("user_repo: UpdatePreferredLanguage: %w", tx.Error)
	}
	if tx.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}
