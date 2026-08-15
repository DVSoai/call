package service

import (
	"context"
	"fmt"

	"callserver/internal/db"
	"callserver/internal/entity"
)

type CallHistoryService struct {
	history *db.CallHistoryRepo
}

func NewCallHistoryService(history *db.CallHistoryRepo) *CallHistoryService {
	return &CallHistoryService{history: history}
}

func (s *CallHistoryService) ListForUser(ctx context.Context, userID string, limit, offset int) ([]entity.CallHistoryEntry, error) {
	entries, err := s.history.ListForUser(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("call_history_service: ListForUser: %w", err)
	}
	return entries, nil
}
