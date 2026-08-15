package service

import (
	"context"
	"fmt"

	"callserver/internal/db"
	"callserver/internal/entity"
)

type ConversationService struct {
	contacts      *db.ContactRepo
	conversations *db.ConversationRepo
	messages      *db.MessageRepo
}

func NewConversationService(contacts *db.ContactRepo, conversations *db.ConversationRepo, messages *db.MessageRepo) *ConversationService {
	return &ConversationService{contacts: contacts, conversations: conversations, messages: messages}
}

// Create — business rule cốt lõi của cả feature Message: "kết bạn mới
// nhắn tin được". direct phải có đúng 1 participant; group thì TẤT CẢ
// participant ban đầu phải là contact (accepted) của creator — không cho
// thêm thẳng người lạ vào ngay cả trong group.
func (s *ConversationService) Create(ctx context.Context, creatorID, conversationType string, participantIDs []string, name *string) (*entity.Conversation, error) {
	if conversationType == entity.ConversationTypeDirect && len(participantIDs) != 1 {
		return nil, ErrDirectNeedsOneParticipant
	}

	for _, otherID := range participantIDs {
		if otherID == creatorID {
			continue
		}
		ok, err := s.contacts.AreContacts(ctx, creatorID, otherID)
		if err != nil {
			return nil, fmt.Errorf("conversation_service: kiểm tra contact: %w", err)
		}
		if !ok {
			return nil, &ErrNotContact{UserID: otherID}
		}
	}

	if conversationType == entity.ConversationTypeDirect {
		existing, err := s.conversations.FindDirectBetween(ctx, creatorID, participantIDs[0])
		if err != nil {
			return nil, fmt.Errorf("conversation_service: FindDirectBetween: %w", err)
		}
		if existing != nil {
			return existing, nil
		}
	}

	conv, err := s.conversations.Create(ctx, conversationType, creatorID, name, participantIDs)
	if err != nil {
		return nil, fmt.Errorf("conversation_service: Create: %w", err)
	}
	return conv, nil
}

func (s *ConversationService) ListForUser(ctx context.Context, userID string, limit, offset int) ([]entity.Conversation, error) {
	list, err := s.conversations.ListForUser(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("conversation_service: ListForUser: %w", err)
	}
	return list, nil
}

// ListParticipants trả về participant (id/phone/displayName) đã gom nhóm
// theo conversationID cho 1 tập conversationIDs trong đúng 1 query — dùng
// bởi handler để đính kèm "participants" vào response GET/POST
// /conversations mà không N+1 (xem ConversationRepo.ListParticipantSummaries).
func (s *ConversationService) ListParticipants(ctx context.Context, conversationIDs []string) (map[string][]entity.ParticipantSummary, error) {
	flat, err := s.conversations.ListParticipantSummaries(ctx, conversationIDs)
	if err != nil {
		return nil, fmt.Errorf("conversation_service: ListParticipants: %w", err)
	}
	grouped := make(map[string][]entity.ParticipantSummary, len(conversationIDs))
	for _, p := range flat {
		grouped[p.ConversationID] = append(grouped[p.ConversationID], p)
	}
	return grouped, nil
}

func (s *ConversationService) ListMessages(ctx context.Context, conversationID, userID string, limit, offset int) ([]entity.Message, error) {
	ok, err := s.conversations.IsParticipant(ctx, conversationID, userID)
	if err != nil {
		return nil, fmt.Errorf("conversation_service: IsParticipant: %w", err)
	}
	if !ok {
		return nil, ErrNotParticipant
	}
	list, err := s.messages.ListForConversation(ctx, conversationID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("conversation_service: ListMessages: %w", err)
	}
	return list, nil
}

// AddParticipants — người thêm (userID) phải đang ở trong conversation,
// và mỗi người được thêm phải là contact (accepted) của userID — cùng
// nguyên tắc "kết bạn mới nhắn tin được" áp dụng khi tạo conversation.
func (s *ConversationService) AddParticipants(ctx context.Context, conversationID, userID string, newUserIDs []string) error {
	ok, err := s.conversations.IsParticipant(ctx, conversationID, userID)
	if err != nil {
		return fmt.Errorf("conversation_service: IsParticipant: %w", err)
	}
	if !ok {
		return ErrNotParticipant
	}

	for _, otherID := range newUserIDs {
		isContact, err := s.contacts.AreContacts(ctx, userID, otherID)
		if err != nil {
			return fmt.Errorf("conversation_service: kiểm tra contact: %w", err)
		}
		if !isContact {
			return &ErrNotContact{UserID: otherID}
		}
	}

	if err := s.conversations.AddParticipants(ctx, conversationID, newUserIDs); err != nil {
		return fmt.Errorf("conversation_service: AddParticipants: %w", err)
	}
	return nil
}

func (s *ConversationService) Leave(ctx context.Context, conversationID, userID string) error {
	return s.conversations.Leave(ctx, conversationID, userID)
}
