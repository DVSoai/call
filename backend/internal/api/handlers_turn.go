package api

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"callserver/internal/auth"
)

type turnCredentialsResponse struct {
	Username string   `json:"username"`
	Password string   `json:"password"`
	TTL      int64    `json:"ttl"`
	URLs     []string `json:"urls"`
}

// handleTURNCredentials — GET /turn-credentials: sinh credential time-
// limited để Client kết nối TURN server (logic thật nằm ở
// service.TurnService — xem docs/CALL_SYSTEM.md §4.4).
func (rt *Router) handleTURNCredentials(c *gin.Context) {
	userID := auth.UserIDFromContext(c)
	creds := rt.turnSvc.GenerateCredentials(userID)

	c.JSON(http.StatusOK, turnCredentialsResponse{
		Username: creds.Username,
		Password: creds.Password,
		TTL:      creds.TTL,
		URLs:     creds.URLs,
	})
}
