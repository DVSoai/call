package db

import (
	"context"
	"fmt"

	"gorm.io/gorm"

	"callserver/internal/entity"
)

// foreignKeys — GORM AutoMigrate không tự tạo FK constraint khi model chỉ
// khai báo cột "xxx_id" dạng string thường (không dùng Go-level
// association/Preload trong repo nào ở đây, cố ý để tránh N+1 ẩn của
// GORM). Thêm FK bằng SQL thô sau AutoMigrate, dùng DO-block để
// idempotent (bỏ qua nếu constraint đã tồn tại) — an toàn gọi lại mỗi lần
// server khởi động.
const foreignKeys = `
DO $$ BEGIN
    ALTER TABLE device_tokens ADD CONSTRAINT fk_device_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE call_history ADD CONSTRAINT fk_call_history_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE call_participants ADD CONSTRAINT fk_call_participants_room FOREIGN KEY (room_id) REFERENCES call_history(room_id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE call_participants ADD CONSTRAINT fk_call_participants_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE contacts ADD CONSTRAINT fk_contacts_requester FOREIGN KEY (requester_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE contacts ADD CONSTRAINT fk_contacts_addressee FOREIGN KEY (addressee_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE contacts ADD CONSTRAINT chk_contacts_status CHECK (status IN ('pending','accepted','rejected','blocked'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE conversations ADD CONSTRAINT fk_conversations_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE conversations ADD CONSTRAINT chk_conversations_type CHECK (conversation_type IN ('direct','group'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE conversation_participants ADD CONSTRAINT fk_participants_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE conversation_participants ADD CONSTRAINT fk_participants_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE messages ADD CONSTRAINT fk_messages_conversation FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE messages ADD CONSTRAINT fk_messages_sender FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
`

// Migrate: bật extension pgcrypto (cần cho gen_random_uuid()), chạy
// AutoMigrate cho toàn bộ model, rồi thêm FK/CHECK constraint bằng SQL thô
// (GORM AutoMigrate không tự quản lý FK khi model không dùng Go
// association). An toàn để gọi lại nhiều lần.
func Migrate(ctx context.Context, gormDB *gorm.DB) error {
	if err := gormDB.WithContext(ctx).Exec(`CREATE EXTENSION IF NOT EXISTS pgcrypto`).Error; err != nil {
		return fmt.Errorf("db: tạo extension pgcrypto thất bại: %w", err)
	}

	if err := gormDB.WithContext(ctx).AutoMigrate(
		&entity.User{},
		&entity.DeviceToken{},
		&entity.CallHistoryEntry{},
		&entity.CallParticipant{},
		&entity.Contact{},
		&entity.Conversation{},
		&entity.ConversationParticipant{},
		&entity.Message{},
	); err != nil {
		return fmt.Errorf("db: AutoMigrate thất bại: %w", err)
	}

	if err := gormDB.WithContext(ctx).Exec(foreignKeys).Error; err != nil {
		return fmt.Errorf("db: tạo foreign key thất bại: %w", err)
	}

	return nil
}
