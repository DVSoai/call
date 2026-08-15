package auth

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

// ContextUserIDKey là key lưu userID đã xác thực vào gin.Context.
const ContextUserIDKey = "userId"

// RequireAuth đọc "Authorization: Bearer <token>", verify JWT, set userID
// vào context cho handler phía sau dùng qua UserIDFromContext.
func (m *Manager) RequireAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := extractToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "thiếu token xác thực"})
			return
		}
		userID, err := m.Verify(token)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "token không hợp lệ"})
			return
		}
		c.Set(ContextUserIDKey, userID)
		c.Next()
	}
}

// extractToken ưu tiên header Authorization; fallback query param ?token=
// vì một số WebSocket client (đặc biệt web) khó set custom header khi mở
// kết nối — GET /ws dùng chung middleware này.
func extractToken(c *gin.Context) string {
	header := c.GetHeader("Authorization")
	if strings.HasPrefix(header, "Bearer ") {
		return strings.TrimPrefix(header, "Bearer ")
	}
	return c.Query("token")
}

// UserIDFromContext lấy userID đã xác thực — chỉ gọi trong handler nằm
// sau RequireAuth().
func UserIDFromContext(c *gin.Context) string {
	userID, _ := c.Get(ContextUserIDKey)
	id, _ := userID.(string)
	return id
}
