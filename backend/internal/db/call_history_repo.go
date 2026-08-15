package db

import (
	"context"
	"fmt"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"callserver/internal/entity"
)

type CallHistoryRepo struct {
	db *gorm.DB
}

func NewCallHistoryRepo(gormDB *gorm.DB) *CallHistoryRepo {
	return &CallHistoryRepo{db: gormDB}
}

// Insert ghi 1 room đã kết thúc (hoặc missed/rejected) cùng toàn bộ
// participant trong 1 transaction. Gọi khi Server nhận call-end hoặc khi
// TTL RINGING hết hạn (missed call).
func (r *CallHistoryRepo) Insert(ctx context.Context, entry entity.CallHistoryEntry) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		row := entity.CallHistoryEntry{
			RoomID:    entry.RoomID,
			CreatedBy: entry.CreatedBy,
			CallType:  entry.CallType,
			Status:    entry.Status,
			StartedAt: entry.StartedAt,
			EndedAt:   entry.EndedAt,
		}
		if err := tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "room_id"}},
			DoUpdates: clause.AssignmentColumns([]string{"status", "ended_at"}),
		}).Create(&row).Error; err != nil {
			return fmt.Errorf("insert room: %w", err)
		}

		for _, userID := range entry.Participants {
			p := entity.CallParticipant{RoomID: entry.RoomID, UserID: userID, JoinedAt: &entry.StartedAt}
			if err := tx.Clauses(clause.OnConflict{DoNothing: true}).Create(&p).Error; err != nil {
				return fmt.Errorf("insert participant %s: %w", userID, err)
			}
		}
		return nil
	})
}

// ListForUser trả về lịch sử cuộc gọi của 1 user (mới nhất trước), kèm
// danh sách participant từng room — dùng cho GET /calls/history. offset
// hỗ trợ phân trang kiểu load-more phía Client (xem ListBlocMixin ở app
// Flutter) — trang N ứng với offset = (N-1) * limit.
func (r *CallHistoryRepo) ListForUser(ctx context.Context, userID string, limit, offset int) ([]entity.CallHistoryEntry, error) {
	var entries []entity.CallHistoryEntry
	err := r.db.WithContext(ctx).
		Select("call_history.*").
		Joins("JOIN call_participants cp ON cp.room_id = call_history.room_id").
		Where("cp.user_id = ?", userID).
		Order("call_history.started_at DESC").
		Limit(limit).Offset(offset).
		Find(&entries).Error
	if err != nil {
		return nil, fmt.Errorf("call_history_repo: ListForUser: %w", err)
	}

	roomIDs := make([]string, 0, len(entries))
	for _, e := range entries {
		roomIDs = append(roomIDs, e.RoomID)
	}
	participantsByRoom, err := r.participantsForRooms(ctx, roomIDs)
	if err != nil {
		return nil, err
	}
	for i := range entries {
		entries[i].Participants = participantsByRoom[entries[i].RoomID]
	}
	return entries, nil
}

func (r *CallHistoryRepo) participantsForRooms(ctx context.Context, roomIDs []string) (map[string][]string, error) {
	result := make(map[string][]string, len(roomIDs))
	if len(roomIDs) == 0 {
		return result, nil
	}

	var rows []entity.CallParticipant
	if err := r.db.WithContext(ctx).Where("room_id IN ?", roomIDs).Find(&rows).Error; err != nil {
		return nil, fmt.Errorf("call_history_repo: participantsForRooms: %w", err)
	}
	for _, row := range rows {
		result[row.RoomID] = append(result[row.RoomID], row.UserID)
	}
	return result, nil
}
