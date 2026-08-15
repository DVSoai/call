package api

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"callserver/internal/auth"
	"callserver/internal/entity"
)

// timeLayout — format thời gian dùng chung cho toàn bộ response JSON có
// time.Time (call history, conversation, message...), RFC3339 khớp với
// DateTime.parse() phía Flutter.
const timeLayout = time.RFC3339

const defaultCallHistoryLimit = 30

// parseIntQuery đọc query param dạng int (limit/offset...), trả về fallback
// nếu thiếu hoặc không hợp lệ — dùng chung cho các endpoint phân trang.
func parseIntQuery(c *gin.Context, key string, fallback int) int {
	v := c.Query(key)
	if v == "" {
		return fallback
	}
	n, err := strconv.Atoi(v)
	if err != nil || n < 0 {
		return fallback
	}
	return n
}

type callHistoryResponse struct {
	RoomID       string   `json:"roomId"`
	CreatedBy    string   `json:"createdBy"`
	CallType     string   `json:"callType"`
	Status       string   `json:"status"`
	StartedAt    string   `json:"startedAt"`
	EndedAt      *string  `json:"endedAt,omitempty"`
	Participants []string `json:"participants"`
}

func toCallHistoryResponse(e entity.CallHistoryEntry) callHistoryResponse {
	resp := callHistoryResponse{
		RoomID:       e.RoomID,
		CreatedBy:    e.CreatedBy,
		CallType:     e.CallType,
		Status:       e.Status,
		StartedAt:    e.StartedAt.Format(timeLayout),
		Participants: e.Participants,
	}
	if e.EndedAt != nil {
		s := e.EndedAt.Format(timeLayout)
		resp.EndedAt = &s
	}
	return resp
}

// handleCallHistory — GET /calls/history?limit=&offset=
func (rt *Router) handleCallHistory(c *gin.Context) {
	userID := auth.UserIDFromContext(c)
	limit := parseIntQuery(c, "limit", defaultCallHistoryLimit)
	offset := parseIntQuery(c, "offset", 0)

	list, err := rt.historySvc.ListForUser(c.Request.Context(), userID, limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể lấy lịch sử cuộc gọi"})
		return
	}

	items := make([]callHistoryResponse, 0, len(list))
	for _, e := range list {
		items = append(items, toCallHistoryResponse(e))
	}
	c.JSON(http.StatusOK, gin.H{"calls": items})
}

// handleRejectCall — POST /calls/:roomId/reject: fallback REST cho reject
// khi Client không có WebSocket sống để tự gửi call-reject (app bị kill,
// quyết định Decline đến từ native code ngoài Flutter engine) — xem
// Hub.RejectCall và android/.../CallRejectNativeHandler.kt.
func (rt *Router) handleRejectCall(c *gin.Context) {
	roomID := c.Param("roomId")
	userID := auth.UserIDFromContext(c)
	if err := rt.hub.RejectCall(c.Request.Context(), roomID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể reject cuộc gọi"})
		return
	}
	c.Status(http.StatusNoContent)
}
