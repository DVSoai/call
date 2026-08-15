package sfu

import (
	"context"
	"fmt"
	"sync"

	"github.com/pion/webrtc/v4"
)

// OfferSender gửi 1 offer SDP mới (đầu tiên hoặc renegotiate) xuống đúng 1
// user trong 1 room — implementation thật do Hub cung cấp lúc wire (gửi
// qua route()/deliverLocal() đã có, dùng lại đúng message type "offer").
type OfferSender func(ctx context.Context, roomID, userID, sdp string)

// ICECandidateSender tương tự OfferSender, cho ICE candidate Server sinh ra
// (trickle ICE) cần gửi xuống Client — dùng lại message type "ice-candidate".
type ICECandidateSender func(ctx context.Context, roomID, userID string, candidate map[string]any)

// Manager quản lý toàn bộ room SFU đang sống trên instance hiện tại.
type Manager struct {
	mu    sync.Mutex
	rooms map[string]*Room

	iceServers []webrtc.ICEServer

	sendOffer        OfferSender
	sendICECandidate ICECandidateSender
}

func NewManager(iceServers []webrtc.ICEServer, sendOffer OfferSender, sendICECandidate ICECandidateSender) *Manager {
	return &Manager{
		rooms:            make(map[string]*Room),
		iceServers:       iceServers,
		sendOffer:        sendOffer,
		sendICECandidate: sendICECandidate,
	}
}

func (m *Manager) roomFor(roomID string) *Room {
	m.mu.Lock()
	defer m.mu.Unlock()
	room, ok := m.rooms[roomID]
	if !ok {
		room = newRoom(roomID, m)
		m.rooms[roomID] = room
	}
	return room
}

// Join tạo 1 Peer mới cho user trong room (tạo room nếu chưa có), sinh offer
// đầu tiên rồi gửi qua sendOffer — gọi khi user bấm Accept
// (POST /calls/:roomId/join).
func (m *Manager) Join(ctx context.Context, roomID, userID string) error {
	return m.roomFor(roomID).addPeer(ctx, userID)
}

// SetAnswer áp answer SDP Client gửi lên làm remote description cho đúng
// Peer của user đó.
func (m *Manager) SetAnswer(roomID, userID, sdp string) error {
	m.mu.Lock()
	room, ok := m.rooms[roomID]
	m.mu.Unlock()
	if !ok {
		return fmt.Errorf("sfu: room %s không tồn tại", roomID)
	}
	return room.setAnswer(userID, sdp)
}

// AddICECandidate áp ICE candidate Client gửi lên cho đúng Peer của user đó.
func (m *Manager) AddICECandidate(roomID, userID string, candidate map[string]any) error {
	m.mu.Lock()
	room, ok := m.rooms[roomID]
	m.mu.Unlock()
	if !ok {
		return fmt.Errorf("sfu: room %s không tồn tại", roomID)
	}
	return room.addICECandidate(userID, candidate)
}

// Leave gỡ Peer khỏi room khi user rời/kết thúc/mất kết nối — hook vào
// Hub.unregister() hiện có. Tự xoá Room nếu rỗng sau khi gỡ.
func (m *Manager) Leave(roomID, userID string) {
	m.mu.Lock()
	room, ok := m.rooms[roomID]
	m.mu.Unlock()
	if !ok {
		return
	}
	if room.removePeer(userID) {
		m.mu.Lock()
		delete(m.rooms, roomID)
		m.mu.Unlock()
	}
}
