package sfu

import (
	"context"
	"fmt"
	"log"
	"sync"

	"github.com/pion/webrtc/v4"
)

// Room quản lý toàn bộ Peer + track audio đang publish trong 1 group call.
// Mỗi Peer nhận forward track audio từ mọi Peer khác (trừ chính nó) — đúng
// mô hình SFU (xem docs/CALL_SYSTEM.md §7.2). Video/simulcast/PLI để dành
// cho giai đoạn sau (v1 chỉ audio, không cần yêu cầu keyframe).
type Room struct {
	id      string
	manager *Manager

	mu         sync.Mutex
	peers      map[string]*Peer
	publishers map[string]*webrtc.TrackLocalStaticRTP // key = userID đang publish audio
}

func newRoom(id string, manager *Manager) *Room {
	return &Room{
		id:         id,
		manager:    manager,
		peers:      make(map[string]*Peer),
		publishers: make(map[string]*webrtc.TrackLocalStaticRTP),
	}
}

// addPeer tạo PeerConnection mới cho user, add sẵn track của những người
// đang publish từ trước (join muộn vẫn nghe được ngay từ offer đầu tiên),
// rồi sinh + gửi offer.
func (r *Room) addPeer(ctx context.Context, userID string) error {
	pc, err := webrtc.NewPeerConnection(webrtc.Configuration{ICEServers: r.manager.iceServers})
	if err != nil {
		return fmt.Errorf("sfu: tạo PeerConnection lỗi: %w", err)
	}

	// Bắt buộc có transceiver recvonly ngay từ đầu để Server nhận được mic
	// của Client — nếu không, offer đầu tiên sẽ không có m-line audio nào
	// theo chiều Client -> Server.
	if _, err := pc.AddTransceiverFromKind(webrtc.RTPCodecTypeAudio, webrtc.RTPTransceiverInit{
		Direction: webrtc.RTPTransceiverDirectionRecvonly,
	}); err != nil {
		_ = pc.Close()
		return fmt.Errorf("sfu: AddTransceiver lỗi: %w", err)
	}

	peer := &Peer{
		UserID:  userID,
		RoomID:  r.id,
		pc:      pc,
		senders: make(map[string]*webrtc.RTPSender),
	}

	pc.OnICECandidate(func(c *webrtc.ICECandidate) {
		if c == nil {
			return
		}
		r.manager.sendICECandidate(context.Background(), r.id, userID, iceCandidateToMap(c.ToJSON()))
	})
	pc.OnTrack(func(track *webrtc.TrackRemote, _ *webrtc.RTPReceiver) {
		r.handleRemoteTrack(peer, track)
	})
	pc.OnConnectionStateChange(func(s webrtc.PeerConnectionState) {
		if s == webrtc.PeerConnectionStateFailed || s == webrtc.PeerConnectionStateClosed {
			r.removePeer(userID)
		}
	})

	r.mu.Lock()
	// User reconnect trong lúc Peer cũ chưa kịp dọn — đóng cái cũ trước,
	// tránh leak goroutine forwardRTP/PeerConnection.
	if old, exists := r.peers[userID]; exists {
		r.mu.Unlock()
		old.close()
		r.mu.Lock()
	}
	r.peers[userID] = peer
	for srcID, track := range r.publishers {
		if srcID == userID {
			continue
		}
		sender, err := pc.AddTrack(track)
		if err != nil {
			log.Printf("sfu: AddTrack (join muộn) lỗi dest=%s src=%s: %v", userID, srcID, err)
			continue
		}
		peer.senders[srcID] = sender
	}
	r.mu.Unlock()

	return r.renegotiate(ctx, peer)
}

func (r *Room) setAnswer(userID, sdp string) error {
	r.mu.Lock()
	peer, ok := r.peers[userID]
	r.mu.Unlock()
	if !ok {
		return fmt.Errorf("sfu: peer %s không tồn tại trong room %s", userID, r.id)
	}
	return peer.pc.SetRemoteDescription(webrtc.SessionDescription{Type: webrtc.SDPTypeAnswer, SDP: sdp})
}

func (r *Room) addICECandidate(userID string, candidate map[string]any) error {
	r.mu.Lock()
	peer, ok := r.peers[userID]
	r.mu.Unlock()
	if !ok {
		return fmt.Errorf("sfu: peer %s không tồn tại trong room %s", userID, r.id)
	}

	init := webrtc.ICECandidateInit{}
	if v, ok := candidate["candidate"].(string); ok {
		init.Candidate = v
	}
	if v, ok := candidate["sdpMid"].(string); ok {
		init.SDPMid = &v
	}
	if v, ok := candidate["sdpMLineIndex"].(float64); ok {
		idx := uint16(v)
		init.SDPMLineIndex = &idx
	}
	return peer.pc.AddICECandidate(init)
}

// handleRemoteTrack chạy khi 1 Peer bắt đầu publish audio (OnTrack) — tạo 1
// TrackLocalStaticRTP dùng chung, add vào mọi Peer khác (fan-out), rồi bơm
// RTP từ track gốc vào track dùng chung đó ở 1 goroutine riêng.
//
// streamID đặt bằng UserID của người publish — Client dựa vào
// MediaStream.id để biết audio vừa nhận là của ai, không cần thêm field
// signaling nào khác (xem WebRtcService phía Flutter).
func (r *Room) handleRemoteTrack(source *Peer, track *webrtc.TrackRemote) {
	localTrack, err := webrtc.NewTrackLocalStaticRTP(track.Codec().RTPCodecCapability, "audio", source.UserID)
	if err != nil {
		log.Printf("sfu: tạo local track lỗi cho user %s: %v", source.UserID, err)
		return
	}

	r.mu.Lock()
	r.publishers[source.UserID] = localTrack
	others := make([]*Peer, 0, len(r.peers))
	for id, p := range r.peers {
		if id != source.UserID {
			others = append(others, p)
		}
	}
	r.mu.Unlock()

	for _, dest := range others {
		r.subscribe(dest, source.UserID, localTrack)
	}

	go forwardRTP(track, localTrack)
}

func (r *Room) subscribe(dest *Peer, sourceUserID string, track *webrtc.TrackLocalStaticRTP) {
	sender, err := dest.pc.AddTrack(track)
	if err != nil {
		log.Printf("sfu: AddTrack lỗi dest=%s src=%s: %v", dest.UserID, sourceUserID, err)
		return
	}
	dest.mu.Lock()
	dest.senders[sourceUserID] = sender
	dest.mu.Unlock()

	if err := r.renegotiate(context.Background(), dest); err != nil {
		log.Printf("sfu: renegotiate lỗi cho user %s: %v", dest.UserID, err)
	}
}

// forwardRTP bơm RTP packet từ track gốc (nhận từ Client publish) sang
// track dùng chung (WriteRTP tự fan-out tới mọi PeerConnection đã AddTrack
// track này) — dừng khi track kết thúc (peer rời/tắt mic).
func forwardRTP(remote *webrtc.TrackRemote, local *webrtc.TrackLocalStaticRTP) {
	for {
		pkt, _, err := remote.ReadRTP()
		if err != nil {
			return
		}
		if err := local.WriteRTP(pkt); err != nil {
			return
		}
	}
}

// removePeer gỡ 1 Peer khỏi room — dọn track nó publish khỏi mọi Peer khác
// (renegotiate lại), đóng PeerConnection. Trả về true nếu room rỗng sau khi
// gỡ (Manager sẽ xoá hẳn Room).
func (r *Room) removePeer(userID string) bool {
	r.mu.Lock()
	peer, ok := r.peers[userID]
	if !ok {
		empty := len(r.peers) == 0
		r.mu.Unlock()
		return empty
	}
	delete(r.peers, userID)
	delete(r.publishers, userID)
	remaining := make([]*Peer, 0, len(r.peers))
	for _, p := range r.peers {
		remaining = append(remaining, p)
	}
	r.mu.Unlock()

	peer.close()

	for _, dest := range remaining {
		dest.mu.Lock()
		sender, exists := dest.senders[userID]
		if exists {
			delete(dest.senders, userID)
		}
		dest.mu.Unlock()
		if !exists {
			continue
		}
		if err := dest.pc.RemoveTrack(sender); err != nil {
			log.Printf("sfu: RemoveTrack lỗi dest=%s src=%s: %v", dest.UserID, userID, err)
			continue
		}
		if err := r.renegotiate(context.Background(), dest); err != nil {
			log.Printf("sfu: renegotiate lỗi sau khi user %s rời: %v", userID, err)
		}
	}

	r.mu.Lock()
	empty := len(r.peers) == 0
	r.mu.Unlock()
	return empty
}

// renegotiate sinh offer mới (đầu tiên hoặc do track set đổi) rồi gửi qua
// Manager.sendOffer. negotiateMu (trên Peer) đảm bảo không có 2 lần
// CreateOffer/SetLocalDescription chồng nhau trên cùng 1 PeerConnection.
func (r *Room) renegotiate(ctx context.Context, p *Peer) error {
	p.negotiateMu.Lock()
	defer p.negotiateMu.Unlock()

	offer, err := p.pc.CreateOffer(nil)
	if err != nil {
		return fmt.Errorf("sfu: CreateOffer lỗi: %w", err)
	}
	if err := p.pc.SetLocalDescription(offer); err != nil {
		return fmt.Errorf("sfu: SetLocalDescription lỗi: %w", err)
	}
	r.manager.sendOffer(ctx, r.id, p.UserID, offer.SDP)
	return nil
}

func iceCandidateToMap(c webrtc.ICECandidateInit) map[string]any {
	m := map[string]any{"candidate": c.Candidate}
	if c.SDPMid != nil {
		m["sdpMid"] = *c.SDPMid
	}
	if c.SDPMLineIndex != nil {
		m["sdpMLineIndex"] = *c.SDPMLineIndex
	}
	return m
}
