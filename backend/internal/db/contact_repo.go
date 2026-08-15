package db

import (
	"context"
	"errors"
	"fmt"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"callserver/internal/entity"
)

var (
	ErrContactAlreadyExists = errors.New("contact_repo: quan hệ đã tồn tại")
	ErrContactBlocked       = errors.New("contact_repo: không thể gửi lời mời tới người này")
	ErrContactNotFound      = errors.New("contact_repo: không tìm thấy lời mời")
)

type ContactRepo struct {
	db *gorm.DB
}

func NewContactRepo(gormDB *gorm.DB) *ContactRepo {
	return &ContactRepo{db: gormDB}
}

func orderPair(a, b string) (low, high string) {
	if a < b {
		return a, b
	}
	return b, a
}

// SendRequest gửi lời mời kết bạn. Nếu phía kia đã gửi lời mời trước đó
// (pending ngược chiều), tự động accept luôn — đúng hành vi UX chuẩn của
// app nhắn tin (2 người cùng bấm kết bạn thì thành bạn ngay, không cần
// người này accept lại người kia).
func (r *ContactRepo) SendRequest(ctx context.Context, requesterID, addresseeID string) (*entity.Contact, error) {
	low, high := orderPair(requesterID, addresseeID)
	var result entity.Contact

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var existing entity.Contact
		err := tx.Clauses(clause.Locking{Strength: "UPDATE"}).
			Where("user_low = ? AND user_high = ?", low, high).
			First(&existing).Error

		switch {
		case errors.Is(err, gorm.ErrRecordNotFound):
			created := entity.Contact{
				RequesterID: requesterID,
				AddresseeID: addresseeID,
				UserLow:     low,
				UserHigh:    high,
				Status:      entity.ContactStatusPending,
			}
			if err := tx.Create(&created).Error; err != nil {
				return fmt.Errorf("insert: %w", err)
			}
			result = created
			return nil

		case err != nil:
			return fmt.Errorf("query existing: %w", err)

		case existing.Status == entity.ContactStatusBlocked:
			return ErrContactBlocked

		case existing.Status == entity.ContactStatusAccepted:
			return ErrContactAlreadyExists

		case existing.Status == entity.ContactStatusPending && existing.RequesterID == requesterID:
			return ErrContactAlreadyExists

		default:
			// pending ngược chiều, hoặc rejected trước đó — coi như gửi lại,
			// đồng thời auto-accept nếu đang là pending ngược chiều.
			newStatus := entity.ContactStatusPending
			if existing.Status == entity.ContactStatusPending {
				newStatus = entity.ContactStatusAccepted
			}
			if err := tx.Model(&existing).Update("status", newStatus).Error; err != nil {
				return fmt.Errorf("update existing: %w", err)
			}
			existing.Status = newStatus
			result = existing
			return nil
		}
	})
	if err != nil {
		if errors.Is(err, ErrContactBlocked) || errors.Is(err, ErrContactAlreadyExists) {
			return nil, err
		}
		return nil, fmt.Errorf("contact_repo: SendRequest: %w", err)
	}
	return &result, nil
}

// Respond xử lý accept/reject — chỉ addressee (người NHẬN lời mời) mới có
// quyền phản hồi.
func (r *ContactRepo) Respond(ctx context.Context, contactID, userID string, accept bool) error {
	newStatus := entity.ContactStatusRejected
	if accept {
		newStatus = entity.ContactStatusAccepted
	}
	tx := r.db.WithContext(ctx).
		Model(&entity.Contact{}).
		Where("id = ? AND addressee_id = ? AND status = ?", contactID, userID, entity.ContactStatusPending).
		Update("status", newStatus)
	if tx.Error != nil {
		return fmt.Errorf("contact_repo: Respond: %w", tx.Error)
	}
	if tx.RowsAffected == 0 {
		return ErrContactNotFound
	}
	return nil
}

// Remove xoá quan hệ (unfriend/huỷ lời mời) — cả requester lẫn addressee
// đều có quyền xoá.
func (r *ContactRepo) Remove(ctx context.Context, contactID, userID string) error {
	tx := r.db.WithContext(ctx).
		Where("id = ? AND (requester_id = ? OR addressee_id = ?)", contactID, userID, userID).
		Delete(&entity.Contact{})
	if tx.Error != nil {
		return fmt.Errorf("contact_repo: Remove: %w", tx.Error)
	}
	if tx.RowsAffected == 0 {
		return ErrContactNotFound
	}
	return nil
}

func (r *ContactRepo) ListAccepted(ctx context.Context, userID string) ([]entity.ContactWithUser, error) {
	return r.listByStatus(ctx, userID, entity.ContactStatusAccepted, "")
}

// ListIncomingRequests — lời mời người khác gửi CHO userID, đang chờ userID phản hồi.
func (r *ContactRepo) ListIncomingRequests(ctx context.Context, userID string) ([]entity.ContactWithUser, error) {
	return r.listByStatus(ctx, userID, entity.ContactStatusPending, "incoming")
}

// ListOutgoingRequests — lời mời userID đã gửi đi, đang chờ người khác phản hồi.
func (r *ContactRepo) ListOutgoingRequests(ctx context.Context, userID string) ([]entity.ContactWithUser, error) {
	return r.listByStatus(ctx, userID, entity.ContactStatusPending, "outgoing")
}

func (r *ContactRepo) listByStatus(ctx context.Context, userID, status, direction string) ([]entity.ContactWithUser, error) {
	q := r.db.WithContext(ctx).
		Table("contacts c").
		Select(`c.id, c.requester_id, c.addressee_id, c.user_low, c.user_high, c.status, c.created_at, c.updated_at,
		        u.id AS other_user_id, u.phone AS other_user_phone, u.display_name AS other_user_display_name`).
		Joins("JOIN users u ON u.id = CASE WHEN c.requester_id = ? THEN c.addressee_id ELSE c.requester_id END", userID).
		Where("c.status = ? AND (c.requester_id = ? OR c.addressee_id = ?)", status, userID, userID)

	switch direction {
	case "incoming":
		q = q.Where("c.addressee_id = ?", userID)
	case "outgoing":
		q = q.Where("c.requester_id = ?", userID)
	}

	var results []entity.ContactWithUser
	if err := q.Order("c.updated_at DESC").Scan(&results).Error; err != nil {
		return nil, fmt.Errorf("contact_repo: listByStatus: %w", err)
	}
	return results, nil
}

// AreContacts kiểm tra 2 user đã là bạn bè (status accepted) chưa — dùng
// để chặn tạo conversation giữa những người chưa kết bạn.
func (r *ContactRepo) AreContacts(ctx context.Context, userA, userB string) (bool, error) {
	low, high := orderPair(userA, userB)
	var count int64
	err := r.db.WithContext(ctx).Model(&entity.Contact{}).
		Where("user_low = ? AND user_high = ? AND status = ?", low, high, entity.ContactStatusAccepted).
		Count(&count).Error
	if err != nil {
		return false, fmt.Errorf("contact_repo: AreContacts: %w", err)
	}
	return count > 0, nil
}
