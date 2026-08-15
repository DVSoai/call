// Command server là entrypoint của callserver — wire toàn bộ module lại
// với nhau. Xem docs/CALL_SYSTEM.md §4.6 cho sơ đồ cấu trúc thư mục.
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/pion/webrtc/v4"

	"callserver/internal/api"
	"callserver/internal/auth"
	"callserver/internal/calls"
	"callserver/internal/config"
	"callserver/internal/db"
	"callserver/internal/push"
	"callserver/internal/service"
	"callserver/internal/signaling"
)

// devCORS cho phép mọi origin — CHỈ dùng cho dev/test (test/client.html
// mở bằng file:// hoặc live-server). Production nên bỏ middleware này
// hoặc thắt lại theo whitelist domain thật.
func devCORS(c *gin.Context) {
	c.Header("Access-Control-Allow-Origin", "*")
	c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type")
	c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS")
	if c.Request.Method == http.MethodOptions {
		c.AbortWithStatus(http.StatusNoContent)
		return
	}
	c.Next()
}

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("config: %v", err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	gormDB, err := db.New(ctx, cfg.PostgresDSN)
	if err != nil {
		log.Fatalf("db: %v", err)
	}
	defer func() {
		if sqlDB, err := gormDB.DB(); err == nil {
			sqlDB.Close()
		}
	}()

	if err := db.Migrate(ctx, gormDB); err != nil {
		log.Fatalf("db migrate: %v", err)
	}

	store := calls.NewStore(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	defer store.Close()
	if err := store.Ping(ctx); err != nil {
		log.Fatalf("redis: %v", err)
	}

	userRepo := db.NewUserRepo(gormDB)
	deviceRepo := db.NewDeviceTokenRepo(gormDB)
	historyRepo := db.NewCallHistoryRepo(gormDB)
	contactRepo := db.NewContactRepo(gormDB)
	conversationRepo := db.NewConversationRepo(gormDB)
	messageRepo := db.NewMessageRepo(gormDB)

	authManager := auth.NewManager(cfg.JWTSecret)
	var dispatcher push.Dispatcher
	if cfg.FirebaseCredentialsPath != "" {
		fcmDispatcher, err := push.NewFCMDispatcher(ctx, cfg.FirebaseCredentialsPath)
		if err != nil {
			log.Fatalf("push: khởi tạo FCMDispatcher: %v", err)
		}
		dispatcher = fcmDispatcher
		log.Println("callserver: dùng FCMDispatcher (push thật qua Firebase)")
	} else {
		dispatcher = push.NewLogDispatcher()
		log.Println("callserver: dùng LogDispatcher (FIREBASE_CREDENTIALS_PATH trống) — push chỉ log ra console")
	}

	authSvc := service.NewAuthService(userRepo, authManager)
	userSvc := service.NewUserService(userRepo)
	deviceSvc := service.NewDeviceService(deviceRepo)
	historySvc := service.NewCallHistoryService(historyRepo)
	contactSvc := service.NewContactService(contactRepo)
	conversationSvc := service.NewConversationService(contactRepo, conversationRepo, messageRepo)
	turnSvc := service.NewTurnService(cfg.TURNSecret, cfg.TURNRealm, cfg.TURNURLs)

	// PeerConnection phía Server (internal/sfu) cũng cần ICE server như
	// Client — dùng lại đúng cơ chế credential time-limited (TurnService),
	// sinh 1 lần lúc khởi động dưới danh nghĩa "sfu-server".
	sfuTurnCreds := turnSvc.GenerateCredentials("sfu-server")
	sfuICEServers := []webrtc.ICEServer{
		{URLs: sfuTurnCreds.URLs, Username: sfuTurnCreds.Username, Credential: sfuTurnCreds.Password},
	}

	hub := signaling.NewHub(store, userRepo, deviceRepo, historyRepo, conversationRepo, messageRepo, dispatcher, cfg.InstanceID, sfuICEServers)
	go hub.Run(ctx)

	router := api.NewRouter(authManager, hub, authSvc, userSvc, deviceSvc, historySvc, contactSvc, conversationSvc, turnSvc)

	engine := gin.Default()
	engine.Use(devCORS) // cho phép test/client.html (file:// hoặc port khác) gọi API lúc dev
	router.Register(engine)
	engine.GET("/healthz", func(c *gin.Context) { c.Status(http.StatusOK) })

	srv := &http.Server{
		Addr:    ":" + cfg.Port,
		Handler: engine,
		// Chỉ áp cho pha đọc/ghi HTTP request thường — KHÔNG ảnh hưởng
		// connection /ws đã hijack() sau khi upgrade (WebSocket sống lâu
		// theo thiết kế, nằm ngoài vòng đời request/response HTTP).
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	go func() {
		log.Printf("callserver: listening on :%s (instance=%s)", cfg.Port, cfg.InstanceID)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("http server: %v", err)
		}
	}()

	<-ctx.Done()
	log.Println("callserver: đang shutdown...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("http server shutdown lỗi: %v", err)
	}
	_ = os.Stdout.Sync()
}
