package push

import (
	"context"
	"log"
)

// LogDispatcher chỉ log ra console — dùng cho giai đoạn test vì chưa có
// tài khoản Firebase / Apple Developer Program. Khi sẵn sàng nối FCM/APNs
// thật, viết Dispatcher mới và đổi ở nơi wire dependency (cmd/server),
// không đụng vào phần còn lại của hệ thống.
type LogDispatcher struct{}

func NewLogDispatcher() *LogDispatcher {
	return &LogDispatcher{}
}

func (d *LogDispatcher) SendCallInvite(_ context.Context, invite CallInvite) error {
	log.Printf("[push:LOG] call invite room=%s caller=%s(%s) type=%s tokens=%v",
		invite.RoomID, invite.CallerName, invite.CallerID, invite.CallType, invite.DeviceTokens)
	return nil
}
