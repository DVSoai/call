package api

import (
	"context"
	"time"

	"github.com/gin-gonic/gin"
)

// requestTimeoutMiddleware giới hạn thời gian tối đa xử lý 1 request REST —
// nếu Postgres/Redis chậm hoặc treo, request bị hủy (context cancelled)
// thay vì giữ goroutine chờ vô thời hạn. KHÔNG áp cho GET /ws: đó là kết
// nối sống lâu theo thiết kế (hàng giờ), tự có cơ chế phát hiện dead
// connection riêng (ping/pong 60s ở internal/signaling/client.go), không
// liên quan gì tới thời gian xử lý 1 HTTP request.
func requestTimeoutMiddleware(timeout time.Duration) gin.HandlerFunc {
	return func(c *gin.Context) {
		ctx, cancel := context.WithTimeout(c.Request.Context(), timeout)
		defer cancel()
		c.Request = c.Request.WithContext(ctx)
		c.Next()
	}
}
