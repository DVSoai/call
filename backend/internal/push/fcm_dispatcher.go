package push

import (
	"context"
	"fmt"
	"log"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"google.golang.org/api/option"
)

// FCMDispatcher gửi push thật qua Firebase Cloud Messaging cho thiết bị
// Android — đây là implementation thứ 2 cho interface Dispatcher, không
// đụng vào Hub hay module nào khác (xem LogDispatcher, dispatcher.go).
// iOS (APNs VoIP) chưa implement — cần Apple Developer Program.
type FCMDispatcher struct {
	client *messaging.Client
}

// NewFCMDispatcher tạo Dispatcher gọi FCM thật bằng service account key
// JSON tải từ Firebase Console (Project settings > Service accounts >
// Generate new private key).
func NewFCMDispatcher(ctx context.Context, credentialsPath string) (*FCMDispatcher, error) {
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsPath))
	if err != nil {
		return nil, fmt.Errorf("fcm_dispatcher: khởi tạo firebase app: %w", err)
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("fcm_dispatcher: khởi tạo messaging client: %w", err)
	}
	return &FCMDispatcher{client: client}, nil
}

// SendCallInvite gửi data message (không kèm "notification") tới toàn bộ
// token android của user — data-only để Client tự dựng UI cuộc gọi đến
// (kể cả khi app đã bị kill, Android vẫn đánh thức được qua data message).
func (d *FCMDispatcher) SendCallInvite(ctx context.Context, invite CallInvite) error {
	tokens := invite.DeviceTokens["android"]
	if len(tokens) == 0 {
		return nil
	}

	data := map[string]string{
		"type":       "call_invite",
		"roomId":     invite.RoomID,
		"callerId":   invite.CallerID,
		"callerName": invite.CallerName,
		"callType":   invite.CallType,
	}

	msg := &messaging.MulticastMessage{
		Tokens: tokens,
		Data:   data,
		Android: &messaging.AndroidConfig{
			Priority: "high", // bắt buộc để OS đánh thức app kể cả khi Doze/background
		},
	}

	resp, err := d.client.SendEachForMulticast(ctx, msg)
	if err != nil {
		return fmt.Errorf("fcm_dispatcher: SendEachForMulticast: %w", err)
	}
	if resp.FailureCount > 0 {
		for i, r := range resp.Responses {
			if !r.Success {
				log.Printf("[push:FCM] gửi lỗi token=%s err=%v", tokens[i], r.Error)
			}
		}
	}
	return nil
}
