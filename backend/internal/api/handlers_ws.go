package api

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"

	"callserver/internal/auth"
)

// upgrader.CheckOrigin cho phép mọi origin — chấp nhận được cho giai đoạn
// dev/test (Client là app Flutter, không phải web browser gọi từ origin
// lạ). Khi có phiên bản web thật, thắt lại theo whitelist domain.
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// handleWebSocket — GET /ws: điểm vào Signaling Hub. Xác thực JWT đã chạy
// qua middleware RequireAuth trước khi tới đây (token truyền qua header
// Authorization hoặc query ?token= — xem internal/auth/middleware.go).
func (rt *Router) handleWebSocket(c *gin.Context) {
	userID := auth.UserIDFromContext(c)

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("api: upgrade WebSocket lỗi cho user %s: %v", userID, err)
		return
	}

	rt.hub.ServeWS(conn, userID)
}
