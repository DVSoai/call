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

type contactResponse struct {
	ID          string `json:"id"`
	Status      string `json:"status"`
	RequesterID string `json:"requesterId"`
	CreatedAt   string `json:"createdAt"`
	OtherUser   struct {
		ID          string `json:"id"`
		Phone       string `json:"phone"`
		DisplayName string `json:"displayName"`
	} `json:"otherUser"`
}

func toContactResponse(c entity.ContactWithUser) contactResponse {
	resp := contactResponse{
		ID:          c.ID,
		Status:      c.Status,
		RequesterID: c.RequesterID,
		CreatedAt:   c.CreatedAt.Format(timeLayout),
	}
	resp.OtherUser.ID = c.OtherUserID
	resp.OtherUser.Phone = c.OtherUserPhone
	resp.OtherUser.DisplayName = c.OtherUserDisplayName
	return resp
}

type sendContactRequestBody struct {
	AddresseeID string `json:"addresseeId" binding:"required"`
}

// handleSendContactRequest — POST /contacts/requests: gửi lời mời kết bạn.
// Client lấy addresseeId từ GET /users/search trước đó.
func (rt *Router) handleSendContactRequest(c *gin.Context) {
	var body sendContactRequestBody
	if err := c.ShouldBindJSON(&body); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu addresseeId"})
		return
	}
	requesterID := auth.UserIDFromContext(c)

	contact, err := rt.contactSvc.SendRequest(c.Request.Context(), requesterID, body.AddresseeID)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrCannotFriendSelf):
			c.JSON(http.StatusBadRequest, gin.H{"error": "không thể tự kết bạn với chính mình"})
		case errors.Is(err, db.ErrContactAlreadyExists):
			c.JSON(http.StatusConflict, gin.H{"error": "đã gửi lời mời hoặc đã là bạn bè"})
		case errors.Is(err, db.ErrContactBlocked):
			c.JSON(http.StatusForbidden, gin.H{"error": "không thể gửi lời mời tới người này"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể gửi lời mời kết bạn"})
		}
		return
	}
	c.JSON(http.StatusCreated, gin.H{"id": contact.ID, "status": contact.Status})
}

// handleListContactRequests — GET /contacts/requests?type=incoming|outgoing
// (mặc định incoming).
func (rt *Router) handleListContactRequests(c *gin.Context) {
	userID := auth.UserIDFromContext(c)
	direction := c.DefaultQuery("type", "incoming")

	var (
		list []entity.ContactWithUser
		err  error
	)
	if direction == "outgoing" {
		list, err = rt.contactSvc.ListOutgoingRequests(c.Request.Context(), userID)
	} else {
		list, err = rt.contactSvc.ListIncomingRequests(c.Request.Context(), userID)
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy danh sách lời mời"})
		return
	}

	items := make([]contactResponse, 0, len(list))
	for _, ct := range list {
		items = append(items, toContactResponse(ct))
	}
	c.JSON(http.StatusOK, gin.H{"requests": items})
}

// handleRespondContactRequest — PUT /contacts/requests/:id/accept|reject.
// accept=true/false chốt tại thời điểm đăng ký route (xem router.go).
func (rt *Router) handleRespondContactRequest(accept bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := auth.UserIDFromContext(c)
		contactID := c.Param("id")

		if err := rt.contactSvc.Respond(c.Request.Context(), contactID, userID, accept); err != nil {
			if errors.Is(err, db.ErrContactNotFound) {
				c.JSON(http.StatusNotFound, gin.H{"error": "không tìm thấy lời mời đang chờ phản hồi"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể phản hồi lời mời"})
			return
		}
		c.Status(http.StatusNoContent)
	}
}

// handleListContacts — GET /contacts: danh sách bạn bè đã accepted.
func (rt *Router) handleListContacts(c *gin.Context) {
	userID := auth.UserIDFromContext(c)
	list, err := rt.contactSvc.ListAccepted(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy danh sách bạn bè"})
		return
	}
	items := make([]contactResponse, 0, len(list))
	for _, ct := range list {
		items = append(items, toContactResponse(ct))
	}
	c.JSON(http.StatusOK, gin.H{"contacts": items})
}

// handleRemoveContact — DELETE /contacts/:id: unfriend hoặc huỷ lời mời.
func (rt *Router) handleRemoveContact(c *gin.Context) {
	userID := auth.UserIDFromContext(c)
	contactID := c.Param("id")

	if err := rt.contactSvc.Remove(c.Request.Context(), contactID, userID); err != nil {
		if errors.Is(err, db.ErrContactNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "không tìm thấy quan hệ này"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể xoá"})
		return
	}
	c.Status(http.StatusNoContent)
}
