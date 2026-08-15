package service

import (
	"crypto/hmac"
	"crypto/sha1"
	"encoding/base64"
	"fmt"
	"time"
)

// turnCredentialTTL — thời hạn credential TURN, đủ dài cho 1 phiên gọi.
const turnCredentialTTL = 12 * time.Hour

type TurnCredentials struct {
	Username string
	Password string
	TTL      int64
	URLs     []string
}

type TurnService struct {
	secret string
	realm  string
	urls   []string
}

func NewTurnService(secret, realm string, urls []string) *TurnService {
	return &TurnService{secret: secret, realm: realm, urls: urls}
}

// GenerateCredentials sinh credential time-limited theo cơ chế shared-secret
// chuẩn coturn (use-auth-secret, HMAC-SHA1) — không gọi API coturn, không
// lưu credential riêng, coturn tự verify vì cùng biết secret.
// Xem docs/CALL_SYSTEM.md §4.4.
func (s *TurnService) GenerateCredentials(userID string) TurnCredentials {
	expiry := time.Now().Add(turnCredentialTTL).Unix()
	username := fmt.Sprintf("%d:%s", expiry, userID)

	mac := hmac.New(sha1.New, []byte(s.secret))
	mac.Write([]byte(username))
	password := base64.StdEncoding.EncodeToString(mac.Sum(nil))

	return TurnCredentials{
		Username: username,
		Password: password,
		TTL:      int64(turnCredentialTTL.Seconds()),
		URLs:     s.urls,
	}
}
