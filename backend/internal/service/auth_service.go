package service

import (
	"context"
	"fmt"

	"callserver/internal/auth"
	"callserver/internal/db"
	"callserver/internal/entity"
)

type AuthService struct {
	users *db.UserRepo
	jwt   *auth.Manager
}

func NewAuthService(users *db.UserRepo, jwt *auth.Manager) *AuthService {
	return &AuthService{users: users, jwt: jwt}
}

// DevLogin — POST /auth/dev-login: đăng nhập theo số điện thoại, tự tạo
// user mới nếu chưa tồn tại, phát hành JWT. Chưa có OTP thật (giai đoạn
// test) — xem docs/CALL_SYSTEM.md §4.5.
func (s *AuthService) DevLogin(ctx context.Context, phone string) (token string, user *entity.User, err error) {
	user, err = s.users.GetOrCreateByPhone(ctx, phone)
	if err != nil {
		return "", nil, fmt.Errorf("auth_service: DevLogin: %w", err)
	}
	token, err = s.jwt.Generate(user.ID)
	if err != nil {
		return "", nil, fmt.Errorf("auth_service: sinh token: %w", err)
	}
	return token, user, nil
}
