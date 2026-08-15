package api

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type devLoginRequest struct {
	Phone string `json:"phone" binding:"required"`
}

type devLoginResponse struct {
	Token string `json:"token"`
	User  struct {
		ID                string `json:"id"`
		Phone             string `json:"phone"`
		DisplayName       string `json:"displayName"`
		PreferredLanguage string `json:"preferredLanguage"`
	} `json:"user"`
}

// handleDevLogin — POST /auth/dev-login: login theo số điện thoại, CHƯA có
// OTP thật, chỉ dùng cho giai đoạn test (xem docs/CALL_SYSTEM.md §4.5).
func (rt *Router) handleDevLogin(c *gin.Context) {
	var req devLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu số điện thoại"})
		return
	}

	token, user, err := rt.authSvc.DevLogin(c.Request.Context(), req.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể đăng nhập"})
		return
	}

	resp := devLoginResponse{Token: token}
	resp.User.ID = user.ID
	resp.User.Phone = user.Phone
	resp.User.DisplayName = user.DisplayName
	resp.User.PreferredLanguage = user.PreferredLanguage
	c.JSON(http.StatusOK, resp)
}
