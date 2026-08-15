package db

import (
	"context"
	"fmt"

	"gorm.io/gorm"

	"callserver/internal/entity"
)

type MessageRepo struct {
	db *gorm.DB
}

func NewMessageRepo(gormDB *gorm.DB) *MessageRepo {
	return &MessageRepo{db: gormDB}
}

// Insert lưu 1 message text — messageType luôn 'text' ở bản hiện tại
// (ảnh/file để giai đoạn sau, xem entity.MessageTypeText).
func (r *MessageRepo) Insert(ctx context.Context, conversationID, senderID, content string) (*entity.Message, error) {
	m := entity.Message{
		ConversationID: conversationID,
		SenderID:       senderID,
		MessageType:    entity.MessageTypeText,
		Content:        content,
	}
	if err := r.db.WithContext(ctx).Create(&m).Error; err != nil {
		return nil, fmt.Errorf("message_repo: Insert: %w", err)
	}
	return &m, nil
}

// ListForConversation trả về message mới nhất trước — Client tự đảo chiều
// nếu muốn hiển thị cũ->mới trong UI (giống ListBlocMixin đã dùng cho
// call_history/contacts).
func (r *MessageRepo) ListForConversation(ctx context.Context, conversationID string, limit, offset int) ([]entity.Message, error) {
	var results []entity.Message
	err := r.db.WithContext(ctx).
		Where("conversation_id = ?", conversationID).
		Order("created_at DESC").
		Limit(limit).Offset(offset).
		Find(&results).Error
	if err != nil {
		return nil, fmt.Errorf("message_repo: ListForConversation: %w", err)
	}
	return results, nil
}
