package signaling

import (
	"context"
	"log"
	"time"
)

const maxLastMessagePreviewLen = 200

// handleChatMessage lưu message vào Postgres rồi broadcast tới toàn bộ
// participant còn hoạt động của conversation (bao gồm cả sender — để các
// thiết bị/tab khác của chính sender cũng nhận được bản chính thức, thay
// optimistic message cục bộ bằng bản có messageId/createdAt thật).
// Dùng chung 1 kết nối WebSocket với call signaling — KHÔNG tách
// chat-server riêng, đúng yêu cầu kiến trúc đã chốt.
func (h *Hub) handleChatMessage(ctx context.Context, c *Client, m Message) {
	if m.ConversationID == "" || m.Payload.Text == "" {
		log.Printf("signaling: chat-message thiếu conversationId hoặc text từ user %s", c.userID)
		return
	}

	isParticipant, err := h.conversations.IsParticipant(ctx, m.ConversationID, c.userID)
	if err != nil {
		log.Printf("signaling: kiểm tra participant lỗi: %v", err)
		return
	}
	if !isParticipant {
		// Không phải thành viên (hoặc đã rời) — im lặng bỏ qua, không lộ
		// thông tin conversation có tồn tại hay không cho request không hợp lệ.
		log.Printf("signaling: user %s gửi chat-message vào conversation %s không thuộc về mình", c.userID, m.ConversationID)
		return
	}

	saved, err := h.messages.Insert(ctx, m.ConversationID, c.userID, m.Payload.Text)
	if err != nil {
		log.Printf("signaling: lưu message lỗi: %v", err)
		return
	}

	preview := saved.Content
	if len(preview) > maxLastMessagePreviewLen {
		preview = preview[:maxLastMessagePreviewLen]
	}
	if err := h.conversations.UpdateLastMessage(ctx, m.ConversationID, preview); err != nil {
		log.Printf("signaling: cập nhật last message lỗi: %v", err)
	}

	participantIDs, err := h.conversations.GetParticipants(ctx, m.ConversationID)
	if err != nil {
		log.Printf("signaling: lấy participants lỗi: %v", err)
		return
	}

	finalMsg := Message{
		Type:           TypeChatMessage,
		From:           c.userID,
		ConversationID: m.ConversationID,
		Payload: Payload{
			Text:      saved.Content,
			MessageID: saved.ID,
			CreatedAt: saved.CreatedAt.Format(time.RFC3339),
		},
	}
	h.broadcastToParticipants(ctx, participantIDs, finalMsg)
}
