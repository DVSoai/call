package api

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"callserver/internal/auth"
	"callserver/internal/db"
	"callserver/internal/entity"
	"callserver/internal/service"
)

const defaultConversationLimit = 30
const defaultMessageLimit = 50

type createConversationRequest struct {
	Type           string   `json:"type" binding:"required,oneof=direct group"`
	ParticipantIDs []string `json:"participantIds" binding:"required,min=1"`
	Name           *string  `json:"name"`
}

type conversationParticipantResponse struct {
	ID          string `json:"id"`
	Phone       string `json:"phone"`
	DisplayName string `json:"displayName"`
}

type conversationResponse struct {
	ID                 string                            `json:"id"`
	Type               string                            `json:"type"`
	Name               *string                           `json:"name,omitempty"`
	CreatedBy          string                            `json:"createdBy"`
	CreatedAt          string                            `json:"createdAt"`
	LastMessageAt      *string                           `json:"lastMessageAt,omitempty"`
	LastMessagePreview *string                           `json:"lastMessagePreview,omitempty"`
	Participants       []conversationParticipantResponse `json:"participants"`
}

// toConversationResponse — participants truyền riêng (không đọc từ
// c.Participants) vì field đó chỉ được điền lúc Create, còn khi List phải
// tra theo batch qua ConversationService.ListParticipants để tránh N+1
// (xem handleListConversations/handleCreateConversation).
func toConversationResponse(c entity.Conversation, participants []entity.ParticipantSummary) conversationResponse {
	resp := conversationResponse{
		ID:                 c.ID,
		Type:               c.Type,
		Name:               c.Name,
		CreatedBy:          c.CreatedBy,
		CreatedAt:          c.CreatedAt.Format(timeLayout),
		LastMessagePreview: c.LastMessagePreview,
		Participants:       make([]conversationParticipantResponse, 0, len(participants)),
	}
	if c.LastMessageAt != nil {
		s := c.LastMessageAt.Format(timeLayout)
		resp.LastMessageAt = &s
	}
	for _, p := range participants {
		resp.Participants = append(resp.Participants, conversationParticipantResponse{
			ID: p.UserID, Phone: p.Phone, DisplayName: p.DisplayName,
		})
	}
	return resp
}

// respondContactError map lỗi business dùng chung giữa create-conversation
// và add-participants (cả 2 đều enforce "kết bạn mới nhắn tin được").
func respondContactError(c *gin.Context, err error) {
	var notContact *service.ErrNotContact
	switch {
	case errors.As(err, &notContact):
		c.JSON(http.StatusForbidden, gin.H{"error": "chỉ có thể tương tác với người đã là bạn bè (userId: " + notContact.UserID + ")"})
	case errors.Is(err, service.ErrDirectNeedsOneParticipant):
		c.JSON(http.StatusBadRequest, gin.H{"error": "conversation direct phải có đúng 1 participantIds"})
	case errors.Is(err, service.ErrNotParticipant):
		c.JSON(http.StatusForbidden, gin.H{"error": "bạn không phải thành viên của conversation này"})
	default:
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể xử lý yêu cầu"})
	}
}

// handleCreateConversation — POST /conversations. Business rule (chỉ tạo
// được giữa các contact đã accepted) nằm ở service.ConversationService.Create.
func (rt *Router) handleCreateConversation(c *gin.Context) {
	var req createConversationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu type hoặc participantIds hợp lệ"})
		return
	}
	creatorID := auth.UserIDFromContext(c)

	conv, err := rt.conversationSvc.Create(c.Request.Context(), creatorID, req.Type, req.ParticipantIDs, req.Name)
	if err != nil {
		respondContactError(c, err)
		return
	}

	grouped, err := rt.conversationSvc.ListParticipants(c.Request.Context(), []string{conv.ID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy thông tin thành viên"})
		return
	}
	c.JSON(http.StatusCreated, toConversationResponse(*conv, grouped[conv.ID]))
}

// handleListConversations — GET /conversations?limit=&offset=
func (rt *Router) handleListConversations(c *gin.Context) {
	limit := parseIntQuery(c, "limit", defaultConversationLimit)
	offset := parseIntQuery(c, "offset", 0)

	userID := auth.UserIDFromContext(c)
	list, err := rt.conversationSvc.ListForUser(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy danh sách conversation"})
		return
	}

	ids := make([]string, 0, len(list))
	for _, conv := range list {
		ids = append(ids, conv.ID)
	}
	grouped, err := rt.conversationSvc.ListParticipants(c.Request.Context(), ids)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy thông tin thành viên"})
		return
	}

	items := make([]conversationResponse, 0, len(list))
	for _, conv := range list {
		items = append(items, toConversationResponse(conv, grouped[conv.ID]))
	}
	c.JSON(http.StatusOK, gin.H{"conversations": items})
}

type messageResponse struct {
	ID             string `json:"id"`
	ConversationID string `json:"conversationId"`
	SenderID       string `json:"senderId"`
	MessageType    string `json:"messageType"`
	Content        string `json:"content"`
	CreatedAt      string `json:"createdAt"`
}

// handleListMessages — GET /conversations/:id/messages?limit=&offset=
func (rt *Router) handleListMessages(c *gin.Context) {
	conversationID := c.Param("id")
	userID := auth.UserIDFromContext(c)
	limit := parseIntQuery(c, "limit", defaultMessageLimit)
	offset := parseIntQuery(c, "offset", 0)

	list, err := rt.conversationSvc.ListMessages(c.Request.Context(), conversationID, userID, limit, offset)
	if err != nil {
		if errors.Is(err, service.ErrNotParticipant) {
			c.JSON(http.StatusForbidden, gin.H{"error": "bạn không phải thành viên của conversation này"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy tin nhắn"})
		return
	}

	items := make([]messageResponse, 0, len(list))
	for _, m := range list {
		items = append(items, messageResponse{
			ID:             m.ID,
			ConversationID: m.ConversationID,
			SenderID:       m.SenderID,
			MessageType:    m.MessageType,
			Content:        m.Content,
			CreatedAt:      m.CreatedAt.Format(timeLayout),
		})
	}
	c.JSON(http.StatusOK, gin.H{"messages": items})
}

type addParticipantsRequest struct {
	UserIDs []string `json:"userIds" binding:"required,min=1"`
}

// handleAddParticipants — POST /conversations/:id/participants.
func (rt *Router) handleAddParticipants(c *gin.Context) {
	conversationID := c.Param("id")
	userID := auth.UserIDFromContext(c)

	var req addParticipantsRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu userIds"})
		return
	}

	if err := rt.conversationSvc.AddParticipants(c.Request.Context(), conversationID, userID, req.UserIDs); err != nil {
		respondContactError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

// handleLeaveConversation — DELETE /conversations/:id/participants/me
func (rt *Router) handleLeaveConversation(c *gin.Context) {
	conversationID := c.Param("id")
	userID := auth.UserIDFromContext(c)

	if err := rt.conversationSvc.Leave(c.Request.Context(), conversationID, userID); err != nil {
		if errors.Is(err, db.ErrConversationNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "bạn không ở trong conversation này"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể rời conversation"})
		return
	}
	c.Status(http.StatusNoContent)
}
