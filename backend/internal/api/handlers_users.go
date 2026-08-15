package api

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"callserver/internal/auth"
	"callserver/internal/service"
)

type updatePreferredLanguageRequest struct {
	Language string `json:"language" binding:"required"`
}

// handleUpdatePreferredLanguage — PUT /users/preferred-language: cập nhật
// ngôn ngữ nghe ưu tiên, chuẩn bị sẵn cho Translated Call (chương 8).
func (rt *Router) handleUpdatePreferredLanguage(c *gin.Context) {
	var req updatePreferredLanguageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu language"})
		return
	}

	userID := auth.UserIDFromContext(c)
	if err := rt.userSvc.UpdatePreferredLanguage(c.Request.Context(), userID, req.Language); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể cập nhật preferred language"})
		return
	}
	c.Status(http.StatusNoContent)
}

type userSummaryResponse struct {
	ID          string `json:"id"`
	Phone       string `json:"phone"`
	DisplayName string `json:"displayName"`
}

// handleSearchUser — GET /users/search?phone=xxx: tìm chính xác theo số
// điện thoại để gửi lời mời kết bạn (chưa hỗ trợ fuzzy search theo tên).
func (rt *Router) handleSearchUser(c *gin.Context) {
	phone := c.Query("phone")
	if phone == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu query param phone"})
		return
	}

	requesterID := auth.UserIDFromContext(c)
	user, err := rt.userSvc.SearchByPhone(c.Request.Context(), requesterID, phone)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrUserNotFound):
			c.JSON(http.StatusNotFound, gin.H{"error": "không tìm thấy user với số điện thoại này"})
		case errors.Is(err, service.ErrCannotSearchSelf):
			c.JSON(http.StatusBadRequest, gin.H{"error": "không thể tìm chính mình"})
		default:
			c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể tìm user"})
		}
		return
	}

	c.JSON(http.StatusOK, userSummaryResponse{ID: user.ID, Phone: user.Phone, DisplayName: user.DisplayName})
}
