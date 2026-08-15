package api

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"callserver/internal/auth"
)

type registerPushTokenRequest struct {
	Platform  string `json:"platform" binding:"required,oneof=android ios"`
	PushToken string `json:"pushToken" binding:"required"`
}

// handleRegisterPushToken — POST /devices/register-push-token: lưu FCM
// token (android) hoặc APNs VoIP token (ios) của 1 thiết bị.
func (rt *Router) handleRegisterPushToken(c *gin.Context) {
	var req registerPushTokenRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu platform hoặc pushToken hợp lệ (android|ios)"})
		return
	}

	userID := auth.UserIDFromContext(c)
	if err := rt.deviceSvc.RegisterToken(c.Request.Context(), userID, req.Platform, req.PushToken); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lưu push token"})
		return
	}
	c.Status(http.StatusNoContent)
}
