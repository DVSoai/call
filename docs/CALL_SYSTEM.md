# TÀI LIỆU KIẾN TRÚC HỆ THỐNG CALL

*Audio Call & Video Call — Client: Flutter · Server: Golang · Chuẩn trải nghiệm Messenger*

> **Mục tiêu tài liệu:** Định nghĩa kiến trúc hệ thống Call (Audio/Video), tách rõ trách nhiệm Client (Flutter) và Server (Golang), kèm danh sách thư viện cụ thể cho từng phía.
>
> **Roadmap đã chốt:** (1) Call 1-1 — triển khai trước, (2) Group Call — kiến trúc SFU, (3) Translated Call — dịch đa ngôn ngữ real-time. Chương 7–8 mô tả hướng mở rộng cho giai đoạn (2) và (3), **chưa triển khai ở bản đầu**.

---

## Mục lục

1. [Tổng quan kiến trúc Client – Server](#1-tổng-quan-kiến-trúc-client--server)
2. [Bảng công nghệ](#2-bảng-công-nghệ--client-flutter-vs-server-golang)
3. [Client (Flutter) — chi tiết trách nhiệm](#3-client-flutter--chi-tiết-trách-nhiệm)
4. [Server (Golang) — chi tiết trách nhiệm](#4-server-golang--chi-tiết-trách-nhiệm)
5. [Luồng cuộc gọi hoàn chỉnh](#5-luồng-cuộc-gọi-hoàn-chỉnh-client--server)
6. [Bảng phân chia trách nhiệm tổng thể](#6-bảng-phân-chia-trách-nhiệm-tổng-thể)
7. [[Roadmap] Group Call — kiến trúc SFU](#7-roadmap-giai-đoạn-sau-group-call--kiến-trúc-sfu)
8. [[Roadmap] Translated Call — đa ngôn ngữ](#8-roadmap-giai-đoạn-sau-translated-call-gọi-đa-ngôn-ngữ-toàn-cầu)

---

## 1. Tổng quan kiến trúc Client – Server

Hệ thống Call gồm hai phía tách biệt rõ trách nhiệm:

- **Client (Flutter):** UI, WebRTC media, Native System Integration (CallKit/PushKit, Telecom/ConnectionService), xử lý audio/video cục bộ trên máy.
- **Server (Golang):** Signaling (trao đổi SDP/ICE), quản lý trạng thái cuộc gọi, gửi Push Notification (FCM/APNs) để đánh thức Client, TURN/STUN relay (tuỳ chọn tự host), xác thực, lưu call history.

**Nguyên tắc quan trọng:** Server **KHÔNG** xử lý audio/video (trừ khi làm SFU cho group call ở giai đoạn sau) — Server chỉ làm nhiệm vụ signaling và điều phối. Media (audio/video) đi thẳng giữa hai Client qua kết nối **P2P WebRTC** (hoặc qua TURN relay khi mạng không cho phép P2P trực tiếp).

### 1.1. Sơ đồ tổng thể

```
   CLIENT A (Flutter)                SERVER (Golang)
   ───────────────────               ───────────────────
   Flutter Call UI                   Signaling Hub
   flutter_webrtc          ◄──────►  Call State Manager
   Native Call Layer       WebSocket Auth / Call History DB
   (CallKit / ConnSvc)     + Push    TURN/STUN (tuỳ chọn)

          ▲                                  ▲
          │   Media P2P (WebRTC)             │
          │   không qua Server               │
          │   (chỉ qua TURN relay nếu         │
          │    P2P trực tiếp thất bại)        │
          ▼                                  ▼

   CLIENT B (Flutter)      ◄──────►  STUN/TURN Server
```

---

## 2. Bảng công nghệ — Client (Flutter) vs Server (Golang)

### 2.1. Client — Flutter

| Hạng mục | Thư viện / công cụ | Ghi chú |
|---|---|---|
| WebRTC engine | `flutter_webrtc` | Wrapper Dart cho WebRTC native (libwebrtc); PeerConnection, MediaStream, DataChannel |
| Signaling transport | `web_socket_channel` | Kết nối WebSocket tới Signaling Server (Go) |
| Incoming Call UI (iOS) | `flutter_callkit_incoming` | Bridge CallKit + PushKit; hiển thị System Call UI khi có cuộc gọi đến |
| Incoming Call UI (Android) | `flutter_callkit_incoming` (dùng chung) | Dùng ConnectionService/Telecom + full-screen notification phía Android |
| Push Notification nhận | `firebase_messaging` | Nhận FCM data message để đánh thức app khi có cuộc gọi đến |
| State management | `flutter_bloc` / `riverpod` | Quản lý CallState (CALLING, RINGING, CONNECTED...) ở tầng Flutter |
| Native bridge | `MethodChannel` / `Pigeon` | Giao tiếp Flutter ↔ Kotlin (Android) / Swift (iOS) cho phần native call layer |
| Permissions | `permission_handler` | Xin quyền Camera, Microphone, Notification |
| Kiểm tra mạng | `connectivity_plus` | Phát hiện đổi mạng WiFi ↔ 4G để trigger ICE restart |

### 2.2. Server — Golang

| Hạng mục | Thư viện / công cụ | Trạng thái |
|---|---|---|
| WebSocket signaling | `gorilla/websocket` | ✅ Đã code |
| WebRTC (nếu cần SFU sau này) | `pion/webrtc` | Chưa cần — để dành chương 7 (Group Call) |
| TURN/STUN server tự host | `coturn` (Docker) | ✅ Đã cấu hình (docker-compose) |
| Push notification — Android | `firebase.google.com/go/v4/messaging` | Chưa nối thật — đang dùng `LogDispatcher` |
| Push notification — iOS VoIP | `sideshow/apns2` | Chưa nối thật — cần Apple Developer Program |
| HTTP API framework | `gin-gonic/gin` | ✅ Đã code |
| Xác thực | `golang-jwt/jwt` | ✅ Đã code |
| Lưu trữ call state / presence | Redis (`go-redis/v9`) | ✅ Đã code |
| Database chính | PostgreSQL (`jackc/pgx`, không dùng ORM) | ✅ Đã code, tự migrate schema |
| Env/config | `joho/godotenv`, `google/uuid` | ✅ Đã code |
| Logging / metrics | `zerolog` + Prometheus `client_golang` | Chưa cần ở giai đoạn test |

> **Vì sao Server không cần `pion/webrtc` cho bản đầu tiên?**
> Với call 1-1 (audio/video), media đi P2P trực tiếp giữa hai Client qua WebRTC, Server chỉ chuyển tiếp SDP/ICE dạng JSON qua WebSocket — không chạm vào audio/video. `pion/webrtc` + kiến trúc SFU chỉ cần thiết khi làm group call nhiều người (mixing/forwarding media), nên để dành cho giai đoạn sau, tránh làm phức tạp hoá bản đầu tiên.

---

## 3. Client (Flutter) — chi tiết trách nhiệm

### 3.1. Flutter — logic & UI

Flutter phụ trách logic và UI của ứng dụng, dùng `flutter_webrtc` + `flutter_bloc`/`riverpod`:

- Call screen, Incoming call screen khi app đang foreground
- Call state (CALLING/RINGING/CONNECTED/ENDED) qua Bloc/Riverpod
- Điều khiển WebRTC: tạo PeerConnection, add track, addIceCandidate
- Mute / Camera on-off / Switch camera / Speaker toggle (gọi xuống Native qua MethodChannel)
- Call timer, Call history hiển thị (dữ liệu lấy từ Server qua REST API)

### 3.2. Native Layer trong Flutter app (Android/iOS)

Native code (Kotlin/Swift) nằm trong project Flutter, giao tiếp qua MethodChannel/Pigeon, dùng các API hệ điều hành — không phải thư viện Flutter/Dart:

| Nền tảng | API / Framework native | Vai trò |
|---|---|---|
| Android | ConnectionService / Telecom API | Đăng ký cuộc gọi vào hệ thống, hiển thị incoming call ở lock screen |
| Android | AudioManager | Quản lý Audio Focus, chuyển route Earpiece/Speaker/Bluetooth |
| Android | Foreground Service | Giữ cuộc gọi sống khi app background |
| Android | NotificationManager (Full-Screen Intent) | Hiển thị full-screen incoming call khi khoá máy (cần quyền `USE_FULL_SCREEN_INTENT`) |
| iOS | CallKit (`CXProvider`, `CXCallController`) | System Call UI, đồng bộ Accept/Reject/Mute với hệ thống |
| iOS | PushKit (`PKPushRegistry`) | Nhận VoIP Push, đánh thức app kể cả khi bị kill |
| iOS | AVAudioSession | Quản lý audio route, xử lý interruption (cuộc gọi GSM, Siri…) |

---

## 4. Server (Golang) — chi tiết trách nhiệm

> Toàn bộ chương này đã có **reference implementation chạy được thật** — xem repo `callserver/`, đặc biệt file `ARCHITECTURE.md` đi kèm code để đối chiếu trực tiếp với từng package.

### 4.1. Signaling Hub

Module trung tâm dùng `gorilla/websocket`, mỗi Client giữ 1 kết nối WebSocket persistent với Server. Nhiệm vụ:

- Xác thực kết nối WebSocket bằng JWT (`golang-jwt/jwt`) ngay khi client connect
- Định tuyến message: nhận SDP Offer từ Client A → forward tới Client B đang online
- Quản lý mapping userID ↔ WebSocket connection — map RAM cho instance hiện tại, kèm Redis để tra cứu user đang ở instance nào khi chạy nhiều instance
- Phát hiện disconnect (ping/pong) để cập nhật trạng thái online/offline

**Cấu trúc message signaling:**

```jsonc
// Client → Server → Client khác
{
  "type": "offer" | "answer" | "ice-candidate" | "call-end" | "call-reject",
  "from": "userA_id",
  "to": "userB_id",
  "callId": "uuid, Server tự sinh khi nhận offer nếu Client chưa gửi",
  "payload": { "sdp": "...", "candidate": "...", "callType": "audio | video" }
}
```

### 4.2. Call State Manager (Redis)

Dùng Redis lưu 2 loại dữ liệu **TẠM THỜI**, tách bạch rõ với dữ liệu bền vững ở PostgreSQL:

| Loại dữ liệu | Key pattern | TTL | Mục đích |
|---|---|---|---|
| Presence | `presence:{userId}` | 45 giây, tự renew qua heartbeat | Biết user đang online, đang ở instance nào — để định tuyến signaling khi scale nhiều instance |
| Call state — RINGING | `call:{callId}` | 30 giây | Không ai trả lời trong 30s → tự hết hạn, coi như missed call, không cần cron job dọn dẹp |
| Call state — CONNECTED | `call:{callId}` | 6 giờ (safety net) | Cuộc gọi đang diễn ra; TTL dài chỉ để phòng trường hợp message `call-end` bị mất |

Redis Pub/Sub cũng được dùng sẵn để forward message giữa nhiều instance Go (mỗi instance subscribe đúng 1 channel riêng theo `instanceID`) — ở giai đoạn 1 instance, cơ chế này gần như không được kích hoạt, nhưng đã có sẵn để không phải sửa lại kiến trúc khi thật sự cần scale.

### 4.2b. Dữ liệu bền vững (PostgreSQL)

Khác với Redis (mất cũng không sao), PostgreSQL lưu dữ liệu cần tồn tại mãi mãi, tự động migrate schema khi server khởi động:

| Bảng | Nội dung |
|---|---|
| `users` | id, phone, display_name, preferred_language (chuẩn bị sẵn cho Translated Call) |
| `device_tokens` | push token FCM/APNs theo từng user + platform |
| `call_history` | caller, callee, loại cuộc gọi, trạng thái, thời gian bắt đầu/kết thúc |

### 4.3. Push Notification — đánh thức Client khi app không mở WebSocket

Khi Client B không có kết nối WebSocket sống (app background/bị kill), Server phải gửi Push để đánh thức:

| Nền tảng | Cơ chế | Thư viện Go |
|---|---|---|
| Android | FCM high-priority data message | `firebase.google.com/go/v4/messaging` |
| iOS | APNs VoIP Push (bắt buộc cho CallKit) | `sideshow/apns2` |

> **Lưu ý bắt buộc:** Với iOS, mọi VoIP Push nhận qua PushKit đều buộc phải trigger `CXProvider.reportNewIncomingCall` ngay lập tức phía Client, nếu không Apple có thể terminate app. Đây là ràng buộc của Apple, Server chỉ cần đảm bảo gửi đúng loại VoIP Push (không phải push thông thường).

> **Trạng thái hiện tại trong code:** Reference implementation đang dùng interface `Dispatcher` với `LogDispatcher` (chỉ log ra console, chưa gọi FCM/APNs thật) — vì cần tài khoản Firebase (free) và Apple Developer Program ($99/năm, bắt buộc để test CallKit thật trên iPhone). Khi sẵn sàng, chỉ cần viết thêm 1 implementation mới cho interface `Dispatcher`, không phải sửa Hub hay bất kỳ module nào khác.

### 4.4. STUN/TURN

Server nên tự host TURN (không chỉ STUN) vì nhiều mạng 4G/công ty chặn kết nối P2P trực tiếp. Hai lựa chọn:

- **coturn** — server TURN chuẩn công nghiệp, không viết bằng Go, deploy như một service riêng (Docker) — lựa chọn ổn định, khuyến nghị cho production, **đã dùng trong reference implementation**
- **pion/turn** — nếu muốn tự viết TURN server bằng Go để dễ tích hợp/monitor chung hệ thống Go hiện có

Credential TURN được cấp theo cơ chế shared-secret chuẩn của coturn (`use-auth-secret`): Server và coturn cùng biết 1 secret, Server tự sinh username/password time-limited (HMAC-SHA1) mà không cần gọi API coturn hay lưu danh sách credential riêng.

### 4.5. REST API

| Endpoint | Chức năng |
|---|---|
| `POST /auth/dev-login` | Login đơn giản theo số điện thoại (chưa có OTP thật — dùng cho giai đoạn test), trả JWT |
| `PUT /users/preferred-language` | Cập nhật ngôn ngữ nghe ưu tiên — chuẩn bị sẵn cho chương 8 (Translated Call) |
| `POST /devices/register-push-token` | Lưu FCM token / APNs VoIP token của thiết bị |
| `GET /calls/history` | Lấy lịch sử cuộc gọi |
| `GET /turn-credentials` | Cấp credential tạm thời (time-limited) để Client kết nối TURN server |
| `GET /ws` | Nâng cấp lên WebSocket, điểm vào của Signaling Hub |

### 4.6. Reference implementation — cấu trúc thư mục

```
cmd/server/main.go          — entrypoint, wire tất cả module lại với nhau
internal/config/            — đọc biến môi trường
internal/db/                — PostgreSQL: connection, schema migration, repository (query)
internal/calls/             — Redis: presence + call state (RINGING/CONNECTED, TTL tự hết hạn)
internal/signaling/         — WebSocket Hub: message schema, client, routing, cross-instance pub/sub
internal/auth/              — JWT sinh/verify
internal/push/              — interface gửi Push, LogDispatcher cho giai đoạn test
internal/api/                — REST handlers + WebSocket upgrade + TURN credential
coturn/turnserver.conf       — cấu hình TURN server cho giai đoạn test
docker-compose.yml           — Postgres + Redis + coturn, chạy local 1 lệnh
test/client.html             — trang test WebSocket signaling bằng trình duyệt, không cần Flutter
```

**Chạy thử:**

```bash
docker compose up -d
cp .env.example .env
go mod tidy
go run ./cmd/server
```

Xem đầy đủ hướng dẫn (test bằng curl, test 2-tab trình duyệt qua `test/client.html`, cách deploy lên VPS) trong `README.md` đi kèm code, và giải thích thiết kế chi tiết trong `ARCHITECTURE.md`.

---

## 5. Luồng cuộc gọi hoàn chỉnh (Client ↔ Server)

### 5.1. Incoming Call — App đang mở (foreground)

```
Client A (Flutter)         Server (Golang)              Client B (Flutter)
      │                          │                              │
      │──WS: offer(sdp)─────────►│                              │
      │                          │──WS: offer(sdp)─────────────►│
      │                          │                              │  hiện Incoming Call UI
      │                          │◄─────WS: answer(sdp)─────────│  (Accept)
      │◄────WS: answer(sdp)──────│                              │
      │◄═══════════ Media P2P (WebRTC) — không qua Server ═════►│
```

### 5.2. Incoming Call — App background/bị kill (cần Push)

```
Client A          Server (Golang)                         Client B
   │                    │                                     │
   │──WS: offer────────►│                                     │
   │                    │  Client B không có WS sống          │
   │                    │──FCM/APNs VoIP Push─────────────────►│
   │                    │                          PushKit/FCM đánh thức app
   │                    │                          CallKit hiện System Call UI
   │                    │◄────WS: (app mở lại) connect─────────│
   │                    │◄────WS: answer(sdp)──────────────────│
   │◄───WS: answer──────│                                      │
   │◄═══════ Media P2P (WebRTC) ═══════════════════════════════►│
```

---

## 6. Bảng phân chia trách nhiệm tổng thể

| Chức năng | Client (Flutter) | Server (Golang) |
|---|---|---|
| Call UI / WebRTC | ✅ `flutter_webrtc` | — |
| Signaling transport | `web_socket_channel` | ✅ `gorilla/websocket` |
| Định tuyến SDP/ICE | — | ✅ |
| Call state (nguồn sự thật) | hiển thị | ✅ Redis |
| Push khi app đóng | nhận (`firebase_messaging`/PushKit) | ✅ gửi (`apns2`, FCM Go SDK) |
| System Call UI | ✅ `flutter_callkit_incoming` | — |
| Audio Focus / Route | ✅ native (AudioManager/AVAudioSession) | — |
| TURN/STUN relay | dùng credential từ Server | ✅ coturn / `pion/turn` |
| Xác thực (JWT) | gửi kèm request | ✅ phát hành & verify |
| Call history | hiển thị | ✅ lưu PostgreSQL |

---

## 7. [Roadmap giai đoạn sau] Group Call — kiến trúc SFU

> **Thứ tự roadmap đã chốt:** Call 1-1 (ổn định production) → **Group Call** → Translated Call. Chương này (Group Call) được ưu tiên triển khai **trước** chương 8 (Translated Call).

### 7.1. Vì sao P2P mesh không dùng được khi đông người

Với call 1-1, mỗi máy chỉ gửi/nhận 1 luồng audio/video — P2P trực tiếp là đủ. Nhưng với group call, P2P mesh (mỗi người kết nối trực tiếp với tất cả người còn lại) không scale được:

```
P2P mesh — KHÔNG dùng được khi đông người

  A ↔ B
  A ↔ C
  A ↔ D
  B ↔ C
  B ↔ D
  C ↔ D

→ N người thì mỗi máy phải encode + gửi đồng thời N-1 luồng
→ 5 người = mỗi máy tốn CPU/băng thông như đang gọi 4 cuộc cùng lúc
→ Máy cấu hình yếu sẽ quá tải gần như ngay lập tức
```

### 7.2. Kiến trúc đúng: SFU (Selective Forwarding Unit)

Mỗi Client chỉ gửi lên 1 luồng duy nhất; SFU (chạy trên Server) nhận và forward luồng đó tới những Client còn lại trong phòng:

```
   Client A ──┐
   Client B ──┼──►  SFU (Golang, pion/webrtc)  ──┬──► forward tới các Client khác
   Client C ──┤        (Server)                   │
   Client D ──┘                                    └──► mỗi Client nhận N-1 luồng,
                                                          chỉ gửi lên 1 luồng
```

Đây là lúc `pion/webrtc` mới thật sự cần dùng ở Server — khác với call 1-1 nơi Server chỉ làm signaling, hoàn toàn không chạm vào media.

### 7.3. Những phần phải bổ sung so với 1-1

| Hạng mục | Call 1-1 (đã có) | Group Call (bổ sung) |
|---|---|---|
| Media routing | P2P trực tiếp | Bắt buộc qua SFU (Golang + pion/webrtc) |
| Signaling | Đơn giản: A ↔ B | Quản lý N participant, join/leave động theo thời gian thực |
| Băng thông Server | ~0, chỉ text signaling | Tốn thật — Server forward media liên tục, chi phí tăng theo số phòng × số người |
| Native Call UI | Hỗ trợ sẵn (CallKit/ConnectionService) | Cần thêm UI nhiều người: grid video, active speaker detection |
| Ghép với Translated Call (sau này) | 2 người = tối đa 2 hướng dịch | N người có thể cần tới N hướng dịch riêng — nên cân nhắc dịch tập trung tại SFU thay vì từng Client tự làm |
| Recording (nếu cần) | Ít đặt ra | Thường được yêu cầu cho group call (họp nhóm, hội thảo) |

### 7.4. Thư viện dự kiến bổ sung — Server (Golang)

| Hạng mục | Thư viện / công cụ | Ghi chú |
|---|---|---|
| SFU engine | `pion/webrtc` | Nhận + forward media track giữa nhiều participant trong cùng phòng |
| Quản lý phòng/room | Mở rộng Signaling Hub hiện có + Redis | Lưu danh sách participant theo roomId, trạng thái join/leave |
| Scale nhiều SFU instance | Redis Pub/Sub hoặc NATS | Khi số phòng đồng thời lớn, cần điều phối giữa nhiều SFU node |

> **Khuyến nghị thứ tự triển khai:** Chỉ bắt đầu thiết kế chi tiết Group Call sau khi call 1-1 đã chạy ổn định production. Thiết kế SFU quá sớm khi 1-1 chưa xong dễ dẫn tới over-engineering và phải sửa lại khi có dữ liệu thực tế từ người dùng.

---

## 8. [Roadmap giai đoạn sau] Translated Call: gọi đa ngôn ngữ toàn cầu

> **Phạm vi:** Triển khai **sau** chương 7 (Group Call). Mục tiêu: hai người gọi nói hai ngôn ngữ khác nhau, mỗi người chọn ngôn ngữ họ muốn NGHE, hệ thống tự dịch theo thời gian thực — ưu tiên xử lý **on-device**, không cần server xử lý audio nặng.

### 8.1. Nguyên tắc kiến trúc

- Mỗi người chọn ngôn ngữ muốn **NGHE** (không có khái niệm "ngôn ngữ chung cuộc gọi")
- Việc dịch xử lý ở **máy người NGHE**, không phải máy người nói — tránh 1 người nói phải tạo N bản dịch cho N người nghe trong group call
- Server (Golang) không xử lý audio dịch — chỉ truyền thêm 1 trường `preferredLanguage` trong signaling message
- Toàn bộ pipeline **ASR → MT → TTS chạy on-device** (client): riêng tư, hoạt động cả khi mạng yếu, không tốn chi phí server theo phút gọi
- Vì triển khai sau Group Call, kiến trúc dịch cần tính toán ngay cho trường hợp N người trong phòng, không chỉ 2 người

### 8.2. Sơ đồ pipeline (chạy trên Client, người nghe)

```
Người kia nói (ngôn ngữ nguồn, qua WebRTC)
        ↓
   [Client — máy người NGHE, xử lý on-device]
        ↓
   VAD (phát hiện điểm ngắt câu)
        ↓
   ASR (Whisper, auto-detect ngôn ngữ nguồn)
        ↓
   MT (dịch sang ngôn ngữ người nghe đã chọn)
        ↓
   Hiển thị Subtitle  (giai đoạn 1)
        hoặc
   TTS → phát giọng dịch qua loa  (giai đoạn 2)
```

### 8.3. Thư viện dự kiến — Client (Flutter)

| Hạng mục | Thư viện / model | Ghi chú |
|---|---|---|
| ASR (Speech-to-Text) | `whisper.cpp` qua `whisper_flutter_new` hoặc `sherpa_onnx` | Model ggml-tiny/base, tải về khi bật tính năng, cache local, **không** bundle sẵn trong repo |
| MT (dịch máy) | Bergamot/Marian NMT hoặc T5-small (ONNX) | Tránh dùng NLLB nếu app có yếu tố thương mại (license CC-BY-NC, cấm thương mại) |
| TTS (giai đoạn 2) | `flutter_tts` (engine TTS có sẵn của OS) | Không cần model TTS riêng — Android TextToSpeech / iOS AVSpeechSynthesizer đã hỗ trợ tiếng Việt |
| Voice Activity Detection | `silero-vad` (ONNX) hoặc VAD tích hợp trong whisper.cpp streaming | Cắt audio theo câu, tránh dịch giữa chừng câu |
| Chạy model ONNX tổng quát | `sherpa_onnx` / `onnxruntime` (flutter binding) | Dùng chung cho ASR và MT nếu chọn model dạng ONNX |

### 8.4. Thay đổi phía Server (Golang) — rất nhỏ

Vì xử lý dịch nằm hoàn toàn ở Client, Server chỉ cần bổ sung:

- Thêm field `preferredLanguage` vào user profile (PostgreSQL) và message signaling — **đã có sẵn trong schema hiện tại**
- REST endpoint `PUT /users/preferred-language` để Client cập nhật lựa chọn ngôn ngữ nghe — **đã code sẵn**
- (Tuỳ chọn, nếu sau này cần fallback cloud cho máy yếu): Server đóng vai trò proxy gọi Cloud Translation API (`cloud.google.com/go/translate`) — Server **không** tự chạy model dịch, chỉ forward request/response để giấu API key khỏi Client

### 8.5. Lộ trình triển khai đề xuất

| Giai đoạn | Nội dung | Độ ưu tiên |
|---|---|---|
| Giai đoạn 1 | Subtitle dịch real-time (ASR + MT on-device, không đụng audio gốc) | Làm trước — nền tảng bắt buộc |
| Giai đoạn 2 | Đọc giọng dịch (TTS hệ thống), cho user bật/tắt | Sau khi giai đoạn 1 ổn định |
| Giai đoạn 3 | Fallback cloud cho máy cấu hình yếu (qua Server proxy) | Tuỳ nhu cầu thực tế |
| Giai đoạn 4 (xa) | Voice cloning — giữ giọng gốc người nói khi phát bản dịch | Không ưu tiên, phức tạp cao |

> **Lưu ý độ trễ:** Vì TTS không thể "rút lại" sau khi phát, hệ thống phải chờ người nói dứt câu (VAD) rồi mới chạy ASR→MT→TTS→phát — độ trễ thực tế mỗi câu khoảng 1.5–3 giây tuỳ cấu hình máy, không mượt như hội thoại thông thường. Cần đặt kỳ vọng đúng với người dùng ngay từ UX (ví dụ hiển thị trạng thái "đang dịch...").

### 8.6. Quy trình thử nghiệm Real-time (bắt buộc trước khi code chính thức)

Mục tiêu cuối cùng của Translated Call luôn là real-time trong lúc đang gọi — không phải bản "dịch file offline". Ba việc dưới đây là các vấn đề kỹ thuật thật sự phải giải quyết:

**a) VAD (Voice Activity Detection) — cắt audio theo câu**
Audio trong cuộc gọi là luồng liên tục, không có điểm dừng rõ ràng. Cần một model VAD nhỏ (`silero-vad`, dạng ONNX) chạy song song để phát hiện khoảng lặng — biết chính xác lúc nào người nói vừa dứt câu, rồi mới đẩy đoạn audio đó vào Whisper.

**b) Chạy song song, không chặn thread audio của WebRTC**
Trong lúc cuộc gọi đang chạy, `flutter_webrtc` có thread riêng xử lý audio real-time. Nếu Whisper (native, tốn CPU) chạy chung thread hoặc chặn main thread, audio cuộc gọi sẽ giật/rớt tiếng ngay lập tức. Bắt buộc:
- Whisper phải chạy ở isolate/thread riêng (Dart isolate hoặc native thread bên Kotlin/Swift)
- Audio cuộc gọi và audio đưa vào Whisper phải là hai bản sao độc lập từ cùng một nguồn

**c) Đo baseline độ trễ trên thiết bị thật trước khi ghép vào WebRTC**
Trước khi tích hợp vào luồng gọi, nên đo nhanh: model tiny/base mất bao lâu để xử lý 1 câu dài 3-5 giây, chạy trực tiếp trên chính dòng máy Android tầm trung và iPhone đời cũ dự kiến target. Việc này cho số liệu thật để quyết định dùng model tiny hay base, có cần giới hạn tính năng theo cấu hình máy hay không.

> **Lưu ý:** Bước đo baseline chỉ là một phép đo nhanh (khoảng 10 phút) để lấy số liệu quyết định, không phải một giai đoạn phát triển sản phẩm riêng biệt. Sau khi có số liệu, đi thẳng vào streaming real-time ghép với WebRTC — đúng mục tiêu sản phẩm ngay từ đầu.
