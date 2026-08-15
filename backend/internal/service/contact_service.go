package service

import (
	"context"
	"fmt"

	"callserver/internal/db"
	"callserver/internal/entity"
)

type ContactService struct {
	contacts *db.ContactRepo
}

func NewContactService(contacts *db.ContactRepo) *ContactService {
	return &ContactService{contacts: contacts}
}

// SendRequest gửi lời mời kết bạn — validate "không tự kết bạn với chính
// mình" ở đây (business rule), phần đảm bảo tính duy nhất/auto-accept
// pending ngược chiều nằm ở repository (data integrity, cần transaction).
func (s *ContactService) SendRequest(ctx context.Context, requesterID, addresseeID string) (*entity.Contact, error) {
	if requesterID == addresseeID {
		return nil, ErrCannotFriendSelf
	}
	contact, err := s.contacts.SendRequest(ctx, requesterID, addresseeID)
	if err != nil {
		return nil, err // giữ nguyên sentinel error (ErrContactAlreadyExists/ErrContactBlocked) cho controller map status code
	}
	return contact, nil
}

func (s *ContactService) Respond(ctx context.Context, contactID, userID string, accept bool) error {
	return s.contacts.Respond(ctx, contactID, userID, accept)
}

func (s *ContactService) ListIncomingRequests(ctx context.Context, userID string) ([]entity.ContactWithUser, error) {
	list, err := s.contacts.ListIncomingRequests(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("contact_service: ListIncomingRequests: %w", err)
	}
	return list, nil
}

func (s *ContactService) ListOutgoingRequests(ctx context.Context, userID string) ([]entity.ContactWithUser, error) {
	list, err := s.contacts.ListOutgoingRequests(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("contact_service: ListOutgoingRequests: %w", err)
	}
	return list, nil
}

func (s *ContactService) ListAccepted(ctx context.Context, userID string) ([]entity.ContactWithUser, error) {
	list, err := s.contacts.ListAccepted(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("contact_service: ListAccepted: %w", err)
	}
	return list, nil
}

func (s *ContactService) Remove(ctx context.Context, contactID, userID string) error {
	return s.contacts.Remove(ctx, contactID, userID)
}

// AreContacts — dùng bởi ConversationService để chặn tạo conversation
// giữa những người chưa kết bạn.
func (s *ContactService) AreContacts(ctx context.Context, userA, userB string) (bool, error) {
	ok, err := s.contacts.AreContacts(ctx, userA, userB)
	if err != nil {
		return false, fmt.Errorf("contact_service: AreContacts: %w", err)
	}
	return ok, nil
}
