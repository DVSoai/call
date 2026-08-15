// Package auth sinh và xác thực JWT cho REST API và WebSocket signaling.
package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// tokenTTL — hợp lý cho giai đoạn dev-login (chưa có refresh token riêng).
// Khi thêm OTP/login thật, cân nhắc rút ngắn kèm refresh token.
const tokenTTL = 30 * 24 * time.Hour

var ErrInvalidToken = errors.New("auth: token không hợp lệ hoặc đã hết hạn")

type Claims struct {
	UserID string `json:"userId"`
	jwt.RegisteredClaims
}

type Manager struct {
	secret []byte
}

func NewManager(secret string) *Manager {
	return &Manager{secret: []byte(secret)}
}

// Generate phát hành JWT cho userID, dùng ngay sau POST /auth/dev-login.
func (m *Manager) Generate(userID string) (string, error) {
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(tokenTTL)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(m.secret)
	if err != nil {
		return "", fmt.Errorf("auth: sign token: %w", err)
	}
	return signed, nil
}

// Verify parse + xác thực chữ ký/hạn dùng, trả về userID nếu hợp lệ.
func (m *Manager) Verify(tokenString string) (string, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenString, claims, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("auth: unexpected signing method %v", t.Header["alg"])
		}
		return m.secret, nil
	})
	if err != nil || !token.Valid {
		return "", ErrInvalidToken
	}
	return claims.UserID, nil
}
