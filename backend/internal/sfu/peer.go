// Package sfu là Selective Forwarding Unit cho Group Call — xem
// docs/CALL_SYSTEM.md §7.2. Khác hẳn call 1-1 (P2P, Server chỉ forward SDP
// text): ở đây Server thật sự tham gia media, mỗi Client giữ đúng 1
// PeerConnection với Server (không phải mesh giữa các Client).
//
// Package này KHÔNG biết gì về WebSocket/Redis/Hub — giao tiếp ra ngoài chỉ
// qua 2 callback (OfferSender/ICECandidateSender) truyền vào lúc tạo
// Manager, để tránh phụ thuộc ngược vào package signaling.
package sfu

import (
	"sync"

	"github.com/pion/webrtc/v4"
)

// Peer bọc đúng 1 PeerConnection giữa 1 user và Server, trong 1 room.
type Peer struct {
	UserID string
	RoomID string

	pc *webrtc.PeerConnection

	// negotiateMu đảm bảo không có 2 lần CreateOffer/SetLocalDescription
	// chạy chồng nhau trên cùng 1 PeerConnection — pion không an toàn nếu
	// gọi đồng thời (xem cảnh báo trong sfu-ws reference implementation).
	negotiateMu sync.Mutex

	mu sync.Mutex
	// senders[sourceUserID][kind] — 1 user có thể publish CẢ audio lẫn
	// video cùng lúc (group video call), mỗi track cần track riêng khi
	// RemoveTrack lúc source rời (xem Room.removePeer).
	senders map[string]map[webrtc.RTPCodecType]*webrtc.RTPSender
	closed  bool
}

func (p *Peer) close() {
	p.mu.Lock()
	if p.closed {
		p.mu.Unlock()
		return
	}
	p.closed = true
	p.mu.Unlock()
	_ = p.pc.Close()
}
