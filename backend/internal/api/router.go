// Package api chứa REST handlers (controller layer: parse request, gọi
// service, map response — KHÔNG chứa business logic) và WebSocket upgrade
// endpoint. Business logic nằm ở internal/service; truy vấn DB nằm ở
// internal/db. Xem docs/CALL_SYSTEM.md §4.5.
package api

import (
	"time"

	"github.com/gin-gonic/gin"

	"callserver/internal/auth"
	"callserver/internal/service"
	"callserver/internal/signaling"
)

// restRequestTimeout — đủ rộng cho Postgres/Redis chậm bất thường nhưng
// vẫn chặn được request treo vô hạn (xem middleware.go).
const restRequestTimeout = 10 * time.Second

type Router struct {
	auth *auth.Manager
	hub  *signaling.Hub

	authSvc         *service.AuthService
	userSvc         *service.UserService
	deviceSvc       *service.DeviceService
	historySvc      *service.CallHistoryService
	contactSvc      *service.ContactService
	conversationSvc *service.ConversationService
	turnSvc         *service.TurnService
}

func NewRouter(
	authManager *auth.Manager,
	hub *signaling.Hub,
	authSvc *service.AuthService,
	userSvc *service.UserService,
	deviceSvc *service.DeviceService,
	historySvc *service.CallHistoryService,
	contactSvc *service.ContactService,
	conversationSvc *service.ConversationService,
	turnSvc *service.TurnService,
) *Router {
	return &Router{
		auth:            authManager,
		hub:             hub,
		authSvc:         authSvc,
		userSvc:         userSvc,
		deviceSvc:       deviceSvc,
		historySvc:      historySvc,
		contactSvc:      contactSvc,
		conversationSvc: conversationSvc,
		turnSvc:         turnSvc,
	}
}

// Register gắn toàn bộ route vào gin.Engine — gọi từ cmd/server/main.go.
func (rt *Router) Register(engine *gin.Engine) {
	// dev-login cũng cần bounded timeout — vẫn chạm Postgres dù không auth.
	engine.POST("/auth/dev-login", requestTimeoutMiddleware(restRequestTimeout), rt.handleDevLogin)

	rest := engine.Group("/")
	rest.Use(rt.auth.RequireAuth(), requestTimeoutMiddleware(restRequestTimeout))
	{
		rest.PUT("/users/preferred-language", rt.handleUpdatePreferredLanguage)
		rest.GET("/users/search", rt.handleSearchUser)
		rest.POST("/devices/register-push-token", rt.handleRegisterPushToken)
		rest.GET("/calls/history", rt.handleCallHistory)
		rest.POST("/calls/:roomId/reject", rt.handleRejectCall)
		rest.GET("/turn-credentials", rt.handleTURNCredentials)

		rest.POST("/contacts/requests", rt.handleSendContactRequest)
		rest.GET("/contacts/requests", rt.handleListContactRequests)
		rest.PUT("/contacts/requests/:id/accept", rt.handleRespondContactRequest(true))
		rest.PUT("/contacts/requests/:id/reject", rt.handleRespondContactRequest(false))
		rest.GET("/contacts", rt.handleListContacts)
		rest.DELETE("/contacts/:id", rt.handleRemoveContact)

		rest.POST("/conversations", rt.handleCreateConversation)
		rest.GET("/conversations", rt.handleListConversations)
		rest.GET("/conversations/:id/messages", rt.handleListMessages)
		rest.POST("/conversations/:id/participants", rt.handleAddParticipants)
		rest.DELETE("/conversations/:id/participants/me", rt.handleLeaveConversation)
	}

	// /ws đăng ký riêng, KHÔNG qua requestTimeoutMiddleware — xem lý do
	// trong middleware.go. Vẫn yêu cầu JWT như các route khác.
	ws := engine.Group("/")
	ws.Use(rt.auth.RequireAuth())
	ws.GET("/ws", rt.handleWebSocket)
}
