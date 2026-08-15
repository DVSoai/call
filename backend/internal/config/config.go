// Package config đọc cấu hình server từ biến môi trường (.env khi dev).
package config

import (
	"fmt"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

// Config gom toàn bộ biến môi trường server cần để khởi động.
type Config struct {
	Port string

	PostgresDSN string

	RedisAddr     string
	RedisPassword string
	RedisDB       int

	JWTSecret string

	// TURNSecret dùng để sinh credential time-limited theo cơ chế
	// use-auth-secret của coturn (HMAC-SHA1) — phải trùng với giá trị
	// static-auth-secret trong coturn/turnserver.conf.
	TURNSecret string
	TURNRealm  string
	TURNURLs   []string

	// InstanceID định danh instance Go hiện tại, dùng làm channel Redis
	// Pub/Sub riêng khi chạy nhiều instance signaling.
	InstanceID string

	// FirebaseCredentialsPath trỏ tới service account JSON tải từ Firebase
	// Console — để trống thì dùng LogDispatcher (chưa gửi push thật).
	FirebaseCredentialsPath string
}

// Load đọc .env (nếu có) rồi build Config từ os.Getenv, áp giá trị mặc định
// hợp lý cho môi trường dev khi biến không được set.
func Load() (*Config, error) {
	_ = godotenv.Load() // .env là tuỳ chọn — không lỗi nếu thiếu (vd. production dùng env thật)

	cfg := &Config{
		Port:          getEnv("PORT", "8080"),
		PostgresDSN:   getEnv("POSTGRES_DSN", "postgres://callserver:callserver@localhost:5432/callserver?sslmode=disable"),
		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		JWTSecret:     getEnv("JWT_SECRET", ""),
		TURNSecret:    getEnv("TURN_SECRET", ""),
		TURNRealm:     getEnv("TURN_REALM", "call.local"),
		InstanceID:    getEnv("INSTANCE_ID", "instance-1"),

		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
	}

	cfg.TURNURLs = []string{"turn:localhost:3478"}
	if turnURLs := getEnv("TURN_URLS", ""); turnURLs != "" {
		parts := strings.Split(turnURLs, ",")
		cfg.TURNURLs = cfg.TURNURLs[:0]
		for _, p := range parts {
			if p = strings.TrimSpace(p); p != "" {
				cfg.TURNURLs = append(cfg.TURNURLs, p)
			}
		}
	}

	if cfg.JWTSecret == "" {
		return nil, fmt.Errorf("config: JWT_SECRET là bắt buộc")
	}
	if cfg.TURNSecret == "" {
		return nil, fmt.Errorf("config: TURN_SECRET là bắt buộc")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v, ok := os.LookupEnv(key); ok && v != "" {
		return v
	}
	return fallback
}
