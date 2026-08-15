// Package push đánh thức Client khi không có WebSocket sống (app
// background/bị kill) — xem docs/CALL_SYSTEM.md §4.3.
package push

import "context"

// CallInvite chứa đủ thông tin để dựng 1 push đánh thức Client cho 1 cuộc
// gọi đến. DeviceTokens gộp theo platform ("android" -> FCM token,
// "ios" -> APNs VoIP token) vì 1 user có thể có nhiều thiết bị.
type CallInvite struct {
	RoomID       string
	CallerID     string
	CallerName   string
	CallType     string // "audio" | "video"
	DeviceTokens map[string][]string
}

// Dispatcher trừu tượng hoá việc gửi push — implementation thật (FCM/APNs)
// chỉ cần thêm mới, không sửa signaling Hub hay bất kỳ module nào khác.
type Dispatcher interface {
	// SendCallInvite gửi push đánh thức Client cho 1 cuộc gọi đến.
	SendCallInvite(ctx context.Context, invite CallInvite) error
}
