package calls

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const presenceTTL = 45 * time.Second

func presenceKey(userID string) string {
	return "presence:" + userID
}

// SetOnline ghi user đang online ở instance nào, TTL 45s — Client phải gửi
// heartbeat (ping WebSocket) đều đặn để Hub gọi lại hàm này renew TTL.
func (s *Store) SetOnline(ctx context.Context, userID, instanceID string) error {
	if err := s.rdb.Set(ctx, presenceKey(userID), instanceID, presenceTTL).Err(); err != nil {
		return fmt.Errorf("calls: SetOnline: %w", err)
	}
	return nil
}

// InstanceOf trả về instanceID nơi user đang có WebSocket sống, hoặc
// ("", false) nếu user offline (key hết hạn / đã xoá).
func (s *Store) InstanceOf(ctx context.Context, userID string) (string, bool, error) {
	instanceID, err := s.rdb.Get(ctx, presenceKey(userID)).Result()
	if errors.Is(err, redis.Nil) {
		return "", false, nil
	}
	if err != nil {
		return "", false, fmt.Errorf("calls: InstanceOf: %w", err)
	}
	return instanceID, true, nil
}

// SetOffline xoá presence — gọi khi Hub phát hiện WebSocket disconnect.
func (s *Store) SetOffline(ctx context.Context, userID string) error {
	if err := s.rdb.Del(ctx, presenceKey(userID)).Err(); err != nil {
		return fmt.Errorf("calls: SetOffline: %w", err)
	}
	return nil
}
