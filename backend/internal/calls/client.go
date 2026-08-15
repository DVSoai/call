// Package calls quản lý state TẠM THỜI trong Redis: presence (user đang
// online ở instance nào) và call/room state (RINGING/CONNECTED, TTL tự hết
// hạn). Không lưu dữ liệu bền vững ở đây — xem internal/db cho phần đó.
package calls

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

type Store struct {
	rdb *redis.Client
}

func NewStore(addr, password string, db int) *Store {
	return &Store{
		rdb: redis.NewClient(&redis.Options{
			Addr:     addr,
			Password: password,
			DB:       db,
		}),
	}
}

func (s *Store) Ping(ctx context.Context) error {
	if err := s.rdb.Ping(ctx).Err(); err != nil {
		return fmt.Errorf("calls: không thể kết nối Redis: %w", err)
	}
	return nil
}

func (s *Store) Close() error {
	return s.rdb.Close()
}
