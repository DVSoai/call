package db

import (
	"context"
	"errors"
	"fmt"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"callserver/internal/entity"
)

var ErrConversationNotFound = errors.New("conversation_repo: không tìm thấy conversation")

type ConversationRepo struct {
	db *gorm.DB
}

func NewConversationRepo(gormDB *gorm.DB) *ConversationRepo {
	return &ConversationRepo{db: gormDB}
}

// FindDirectBetween trả về conversation direct đã tồn tại giữa 2 user (nếu
// có) — tránh tạo trùng nhiều conversation 1-1 cho cùng 1 cặp người.
func (r *ConversationRepo) FindDirectBetween(ctx context.Context, userA, userB string) (*entity.Conversation, error) {
	var c entity.Conversation
	err := r.db.WithContext(ctx).
		Where("conversation_type = ?", entity.ConversationTypeDirect).
		Where("EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = conversations.id AND user_id = ?)", userA).
		Where("EXISTS (SELECT 1 FROM conversation_participants WHERE conversation_id = conversations.id AND user_id = ?)", userB).
		First(&c).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("conversation_repo: FindDirectBetween: %w", err)
	}
	return &c, nil
}

// Create tạo conversation (direct hoặc group) kèm participant trong 1
// transaction — participantIDs KHÔNG bao gồm creatorID, hàm tự thêm
// creator vào với role owner.
func (r *ConversationRepo) Create(ctx context.Context, conversationType, creatorID string, name *string, participantIDs []string) (*entity.Conversation, error) {
	c := entity.Conversation{Type: conversationType, Name: name, CreatedBy: creatorID}

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&c).Error; err != nil {
			return fmt.Errorf("insert conversation: %w", err)
		}

		if err := tx.Create(&entity.ConversationParticipant{
			ConversationID: c.ID, UserID: creatorID, Role: entity.ParticipantRoleOwner, JoinedAt: c.CreatedAt,
		}).Error; err != nil {
			return fmt.Errorf("add creator: %w", err)
		}

		for _, uid := range participantIDs {
			if uid == creatorID {
				continue
			}
			p := entity.ConversationParticipant{ConversationID: c.ID, UserID: uid, Role: entity.ParticipantRoleMember, JoinedAt: c.CreatedAt}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&p).Error; err != nil {
				return fmt.Errorf("add participant %s: %w", uid, err)
			}
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("conversation_repo: Create: %w", err)
	}
	c.Participants = append([]string{creatorID}, participantIDs...)
	return &c, nil
}

// ListForUser trả về conversation của user, mới nhất (theo last_message_at,
// fallback created_at nếu chưa có message nào) trước.
func (r *ConversationRepo) ListForUser(ctx context.Context, userID string, limit, offset int) ([]entity.Conversation, error) {
	var results []entity.Conversation
	err := r.db.WithContext(ctx).
		Select("conversations.*").
		Joins("JOIN conversation_participants cp ON cp.conversation_id = conversations.id").
		Where("cp.user_id = ? AND cp.left_at IS NULL", userID).
		Order("COALESCE(conversations.last_message_at, conversations.created_at) DESC").
		Limit(limit).Offset(offset).
		Find(&results).Error
	if err != nil {
		return nil, fmt.Errorf("conversation_repo: ListForUser: %w", err)
	}
	return results, nil
}

// GetParticipants trả về toàn bộ userID đang là thành viên còn hoạt động
// (chưa left) của 1 conversation — dùng để broadcast message qua WebSocket
// (internal/signaling) và kiểm tra quyền truy cập.
func (r *ConversationRepo) GetParticipants(ctx context.Context, conversationID string) ([]string, error) {
	var ids []string
	err := r.db.WithContext(ctx).Model(&entity.ConversationParticipant{}).
		Where("conversation_id = ? AND left_at IS NULL", conversationID).
		Pluck("user_id", &ids).Error
	if err != nil {
		return nil, fmt.Errorf("conversation_repo: GetParticipants: %w", err)
	}
	return ids, nil
}

func (r *ConversationRepo) IsParticipant(ctx context.Context, conversationID, userID string) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).Model(&entity.ConversationParticipant{}).
		Where("conversation_id = ? AND user_id = ? AND left_at IS NULL", conversationID, userID).
		Count(&count).Error
	if err != nil {
		return false, fmt.Errorf("conversation_repo: IsParticipant: %w", err)
	}
	return count > 0, nil
}

// AddParticipants thêm thành viên vào group — chỉ áp dụng conversation_type
// = 'group' (không chặn ở DB layer, service.ConversationService chịu
// trách nhiệm kiểm tra type trước khi gọi).
func (r *ConversationRepo) AddParticipants(ctx context.Context, conversationID string, userIDs []string) error {
	for _, uid := range userIDs {
		p := entity.ConversationParticipant{ConversationID: conversationID, UserID: uid, Role: entity.ParticipantRoleMember}
		err := r.db.WithContext(ctx).Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "conversation_id"}, {Name: "user_id"}},
			DoUpdates: clause.AssignmentColumns([]string{"left_at"}),
		}).Create(&p).Error
		if err != nil {
			return fmt.Errorf("conversation_repo: AddParticipants %s: %w", uid, err)
		}
	}
	return nil
}

// Leave đánh dấu user rời conversation (left_at) thay vì xoá row — giữ lại
// lịch sử tham gia.
func (r *ConversationRepo) Leave(ctx context.Context, conversationID, userID string) error {
	tx := r.db.WithContext(ctx).Model(&entity.ConversationParticipant{}).
		Where("conversation_id = ? AND user_id = ? AND left_at IS NULL", conversationID, userID).
		Update("left_at", gorm.Expr("now()"))
	if tx.Error != nil {
		return fmt.Errorf("conversation_repo: Leave: %w", tx.Error)
	}
	if tx.RowsAffected == 0 {
		return ErrConversationNotFound
	}
	return nil
}

// ListParticipantSummaries trả về thông tin cơ bản (id/phone/displayName)
// của toàn bộ thành viên đang hoạt động (chưa left) cho 1 tập
// conversationIDs trong đúng 1 query — tránh N+1 khi trả participants cho
// danh sách N conversation (GET /conversations).
func (r *ConversationRepo) ListParticipantSummaries(ctx context.Context, conversationIDs []string) ([]entity.ParticipantSummary, error) {
	if len(conversationIDs) == 0 {
		return nil, nil
	}
	var results []entity.ParticipantSummary
	err := r.db.WithContext(ctx).
		Table("conversation_participants cp").
		Select("cp.conversation_id AS conversation_id, u.id AS user_id, u.phone AS phone, u.display_name AS display_name").
		Joins("JOIN users u ON u.id = cp.user_id").
		Where("cp.conversation_id IN ? AND cp.left_at IS NULL", conversationIDs).
		Scan(&results).Error
	if err != nil {
		return nil, fmt.Errorf("conversation_repo: ListParticipantSummaries: %w", err)
	}
	return results, nil
}

// UpdateLastMessage cập nhật cache last_message_* — gọi ngay sau khi
// MessageRepo.Insert thành công, để GET /conversations không phải JOIN
// messages mỗi lần load danh sách.
func (r *ConversationRepo) UpdateLastMessage(ctx context.Context, conversationID, preview string) error {
	err := r.db.WithContext(ctx).Model(&entity.Conversation{}).Where("id = ?", conversationID).
		Updates(map[string]any{"last_message_at": gorm.Expr("now()"), "last_message_preview": preview}).Error
	if err != nil {
		return fmt.Errorf("conversation_repo: UpdateLastMessage: %w", err)
	}
	return nil
}
