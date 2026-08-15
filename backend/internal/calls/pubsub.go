package calls

import (
	"context"
	"fmt"

	"github.com/redis/go-redis/v9"
)

// instanceChannel là channel Pub/Sub riêng cho từng instance Go — dùng để
// forward message signaling khi user gửi/nhận nằm ở 2 instance khác nhau
// (chạy nhiều instance sau lb). Ở giai đoạn 1 instance, cơ chế này gần như
// không được kích hoạt nhưng đã có sẵn để không phải sửa kiến trúc sau này.
func instanceChannel(instanceID string) string {
	return "instance:" + instanceID
}

// PublishToInstance gửi raw message signaling (JSON) tới đúng instance đang
// giữ WebSocket của user đích.
func (s *Store) PublishToInstance(ctx context.Context, instanceID string, message []byte) error {
	if err := s.rdb.Publish(ctx, instanceChannel(instanceID), message).Err(); err != nil {
		return fmt.Errorf("calls: PublishToInstance: %w", err)
	}
	return nil
}

// SubscribeInstance trả về *redis.PubSub của channel riêng cho instance
// hiện tại — caller (signaling Hub) đọc qua .Channel() rồi forward tới
// WebSocket connection tương ứng trên instance này.
func (s *Store) SubscribeInstance(ctx context.Context, instanceID string) *redis.PubSub {
	return s.rdb.Subscribe(ctx, instanceChannel(instanceID))
}
