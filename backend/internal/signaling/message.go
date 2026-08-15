package signaling

import "encoding/json"

// MessageType — 5 loại gốc theo schema đã chốt ở docs/CALL_SYSTEM.md §4.1,
// cộng thêm TypeChatMessage cho tính năng nhắn tin (mở rộng KHÔNG đổi field
// cũ — chỉ thêm type mới + field mới optional, giữ nguyên contract cũ).
type MessageType string

const (
	TypeOffer        MessageType = "offer"
	TypeAnswer       MessageType = "answer"
	TypeICECandidate MessageType = "ice-candidate"
	TypeCallEnd      MessageType = "call-end"
	TypeCallReject   MessageType = "call-reject"

	// TypeChatMessage dùng chung 1 kết nối WebSocket với call signaling
	// (không tách chat-server riêng) — xem handlers_chat.go.
	TypeChatMessage MessageType = "chat-message"
)

// Payload giữ nguyên "candidate" dạng json.RawMessage vì cấu trúc
// RTCIceCandidate (candidate/sdpMid/sdpMLineIndex) do Client tự định
// nghĩa — Server không cần hiểu, chỉ forward nguyên vẹn.
type Payload struct {
	SDP       string          `json:"sdp,omitempty"`
	Candidate json.RawMessage `json:"candidate,omitempty"`
	CallType  string          `json:"callType,omitempty"`

	// Mode — "group" cho Group Call (SFU, xem docs/CALL_SYSTEM.md §7),
	// trống/"direct" cho call 1-1 như cũ. Chỉ set ở message đầu tiên (lời
	// mời) để Client biết cần vào luồng group thay vì P2P thông thường —
	// message thêm mới hoàn toàn, không đổi field cũ nào.
	Mode string `json:"mode,omitempty"`

	// Các field dưới đây chỉ dùng cho TypeChatMessage.
	Text      string `json:"text,omitempty"`
	MessageID string `json:"messageId,omitempty"` // Server sinh, echo lại cho Client match với optimistic message
	CreatedAt string `json:"createdAt,omitempty"` // RFC3339, Server sinh
}

// Message — "callId" đóng vai trò roomId cho call (room-ready: xem
// internal/calls); "conversationId" đóng vai trò tương tự cho chat —
// KHÔNG dùng chung 1 field vì call và chat là 2 khái niệm độc lập (1 user
// có thể vừa gọi vừa nhắn tin đồng thời với 2 người khác nhau).
type Message struct {
	Type           MessageType `json:"type"`
	From           string      `json:"from"`
	To             string      `json:"to,omitempty"`
	CallID         string      `json:"callId,omitempty"`
	ConversationID string      `json:"conversationId,omitempty"`
	Payload        Payload     `json:"payload"`
}
