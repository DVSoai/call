package service

import (
	"context"
	"fmt"

	"callserver/internal/db"
	"callserver/internal/entity"
)

type UserService struct {
	users *db.UserRepo
}

func NewUserService(users *db.UserRepo) *UserService {
	return &UserService{users: users}
}

func (s *UserService) UpdatePreferredLanguage(ctx context.Context, userID, language string) error {
	if err := s.users.UpdatePreferredLanguage(ctx, userID, language); err != nil {
		return fmt.Errorf("user_service: UpdatePreferredLanguage: %w", err)
	}
	return nil
}

// SearchByPhone — GET /users/search?phone=: tìm chính xác theo số điện
// thoại để gửi lời mời kết bạn (chưa hỗ trợ fuzzy search theo tên).
func (s *UserService) SearchByPhone(ctx context.Context, requesterID, phone string) (*entity.User, error) {
	user, err := s.users.GetByPhone(ctx, phone)
	if err != nil {
		return nil, fmt.Errorf("user_service: SearchByPhone: %w", err)
	}
	if user == nil {
		return nil, ErrUserNotFound
	}
	if user.ID == requesterID {
		return nil, ErrCannotSearchSelf
	}
	return user, nil
}
