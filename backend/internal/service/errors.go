// Package service chứa business logic thuần (không import gin/net-http) —
// nằm giữa internal/api (controller: parse request/map response) và
// internal/db (repository: SQL). Mỗi service ứng với 1 domain nghiệp vụ,
// không phải 1-1 với REST resource.
package service

import "errors"

var (
	ErrUserNotFound              = errors.New("service: không tìm thấy user")
	ErrCannotSearchSelf          = errors.New("service: không thể tìm chính mình")
	ErrCannotFriendSelf          = errors.New("service: không thể tự kết bạn với chính mình")
	ErrDirectNeedsOneParticipant = errors.New("service: conversation direct phải có đúng 1 participant")
	ErrNotParticipant            = errors.New("service: bạn không phải thành viên của conversation này")
)

// ErrNotContact — trả kèm userID cụ thể để controller build thông báo lỗi
// rõ ràng ("chỉ có thể nhắn tin với người đã là bạn bè: <userId>").
type ErrNotContact struct{ UserID string }

func (e *ErrNotContact) Error() string {
	return "service: chưa kết bạn với user " + e.UserID
}
