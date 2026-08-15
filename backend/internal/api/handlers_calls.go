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

type createGroupCallRequest struct {
	ParticipantIDs []string `json:"participantIds" binding:"required,min=1"`
	CallType       string   `json:"callType"`
	// ConversationID — tuỳ chọn, nhưng NÊN truyền khi gọi từ 1 group
	// conversation nhắn tin có sẵn: cho phép Server nhận ra "group này đang
	// có cuộc gọi sống" để JOIN LẠI thay vì tạo room mới (xem
	// Hub.CreateGroupCall) — không truyền thì mỗi lần gọi luôn tạo room mới.
	ConversationID string `json:"conversationId"`
}

// handleCreateGroupCall — POST /calls/group: tạo 1 Group Call (SFU) mời N
// người — participantIds thường lấy từ 1 group conversation nhắn tin đã có
// sẵn (không tự validate lại quan hệ bạn bè ở đây, đã validate lúc tạo
// conversation đó rồi). Trả về roomId để Client gọi tiếp
// POST /calls/:roomId/join lúc user bấm Accept — xem Hub.CreateGroupCall.
func (rt *Router) handleCreateGroupCall(c *gin.Context) {
	var req createGroupCallRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "thiếu participantIds hợp lệ"})
		return
	}
	creatorID := auth.UserIDFromContext(c)
	roomID, err := rt.hub.CreateGroupCall(c.Request.Context(), creatorID, req.ConversationID, req.ParticipantIDs, req.CallType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể tạo group call"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"roomId": roomID})
}

// handleJoinGroupCall — POST /calls/:roomId/join: user vừa bấm Accept,
// chính thức tham gia SFU room — tạo Peer, Server tự sinh offer gửi xuống
// qua WS (route lại đúng message type "offer" đã có, xem Hub.sendSFUOffer).
func (rt *Router) handleJoinGroupCall(c *gin.Context) {
	roomID := c.Param("roomId")
	userID := auth.UserIDFromContext(c)
	if err := rt.hub.JoinGroupCall(c.Request.Context(), roomID, userID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "không thể tham gia group call"})
		return
	}
	c.Status(http.StatusNoContent)
}
