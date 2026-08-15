# ARCHITECTURE — callserver

Giải thích quyết định thiết kế của từng package, đối chiếu trực tiếp với `docs/CALL_SYSTEM.md`.
Đọc file đó trước nếu chưa quen tổng quan kiến trúc Client/Server.

## Quyết định nền tảng: "room-ready" ngay từ bản đầu

Tài liệu gốc đề xuất roadmap Call 1-1 → Group Call (SFU) → Translated Call, và khuyến nghị
không viết SFU quá sớm. Nhưng để tránh phải đập lại schema/signaling khi thêm Group Call sau
này, toàn bộ hệ thống được thiết kế xoay quanh khái niệm **room** ngay từ đầu:

- `callId` trong message signaling **chính là `roomId`** — không phải ID riêng cho quan hệ 2 người.
- Call 1-1 chỉ là một room có đúng 2 participant. Redis (`RoomState.Participants []string`) và
  PostgreSQL (bảng `call_participants`) đều lưu participant dạng danh sách, không phải 2 cột
  `caller_id`/`callee_id` cố định.
- Điều **chưa** làm: media forwarding thật (SFU, `pion/webrtc`). Media call 1-1 vẫn đi P2P trực
  tiếp giữa 2 Client. Khi cần Group Call, chỉ thêm 1 module SFU mới đọc cùng room/participant đã
  có sẵn — không phải viết lại tầng dữ liệu.

## internal/config

Đọc `.env` (dev) hoặc biến môi trường thật (production) qua `godotenv` + `os.Getenv`. Fail-fast
nếu thiếu `JWT_SECRET`/`TURN_SECRET` — đây là 2 secret bắt buộc, không có giá trị mặc định an
toàn để tự sinh.

## internal/db (PostgreSQL, không ORM)

Dùng `jackc/pgx/v5` + `pgxpool` thuần, SQL viết tay. `Migrate()` chạy `CREATE TABLE IF NOT
EXISTS` mỗi lần khởi động — đủ cho schema nhỏ, ổn định; không cần công cụ migration riêng
(golang-migrate...) ở giai đoạn này.

Bảng:
- `users` — có sẵn `preferred_language` dù Translated Call (chương 8) chưa triển khai, vì thêm
  cột sau này cho bảng đã có dữ liệu tốn công hơn nhiều so với thêm ngay từ đầu.
- `device_tokens` — 1 user có thể có nhiều thiết bị/platform, unique theo (user, platform, token).
- `call_history` + `call_participants` — tách 2 bảng (room-ready, xem trên) thay vì 1 bảng
  `caller_id/callee_id` cố định.

## internal/calls (Redis — state TẠM THỜI)

Hai loại key, TTL khác nhau, đúng theo §4.2 tài liệu gốc:

| Key | TTL | Vì sao |
|---|---|---|
| `presence:{userId}` | 45s, renew qua ping/pong WebSocket | User mất kết nối đột ngột (rớt mạng, kill app) sẽ tự "biến mất" khỏi presence sau tối đa 45s mà không cần dọn dẹp thủ công |
| `call:{roomId}` — RINGING | 30s | Không ai trả lời → tự thành missed call, không cần cron job |
| `call:{roomId}` — CONNECTED | 6 giờ | Chỉ là safety net phòng message `call-end` bị mất giữa đường — bình thường room bị xoá tường minh khi Hub nhận `call-end`/`call-reject` |

Pub/Sub theo `instance:{instanceID}` đã viết sẵn (`pubsub.go`) dù ở 1 instance không kích hoạt
thật — tránh phải sửa kiến trúc signaling khi scale ngang.

## internal/auth

JWT HS256, `golang-jwt/jwt/v5`. Middleware `RequireAuth()` đọc token từ header `Authorization:
Bearer` hoặc query `?token=` (fallback cho WebSocket upgrade — khó set custom header khi mở
kết nối WS ở một số client).

## internal/push

Interface `Dispatcher` với 2 implementation: `LogDispatcher` (chỉ log ra console, dùng khi chưa
cấu hình Firebase) và `FCMDispatcher` (**đã nối thật** — gửi FCM data message priority cao qua
`firebase.google.com/go/v4/messaging`). `cmd/server/main.go` tự chọn dựa trên
`cfg.FirebaseCredentialsPath` (env `FIREBASE_CREDENTIALS_PATH`, trỏ tới service account JSON tải
từ Firebase Console) — trống thì fallback `LogDispatcher`. iOS (`apns2`) chưa làm, cần Apple
Developer Program thật.

## internal/signaling (Hub — module trung tâm)

- `Client` (`client.go`): bọc 1 `*websocket.Conn`. `writePump()` là goroutine **duy nhất** ghi
  vào conn (bắt buộc theo ràng buộc thread-safety của `gorilla/websocket`) — nhận message từ
  cả routing trực tiếp lẫn Redis Pub/Sub qua cùng 1 channel `send`.
- `Hub` (`hub.go`): map `userID -> *Client` **local cho instance hiện tại**. Khi user gửi/nhận
  không cùng instance, tra `presence:{userId}` để biết instance đích rồi publish qua Redis.
- `handlers.go`: xử lý từng `MessageType`.
  - `offer`: sinh `roomId` nếu Client chưa gửi, tạo `RoomState` RINGING (kèm lưu `OfferSDP`), thử
    route trực tiếp — nếu callee offline hoàn toàn (không có presence ở instance nào), gọi
    `push.Dispatcher`. Đồng thời `SetPendingOffer(calleeID, roomID)` (Redis, TTL = ringingTTL) để
    `Hub.register()` tự redeliver lại offer này nếu callee reconnect trước khi room hết hạn (bù
    cho việc offer chỉ forward sống 1 lần — callee bị đánh thức qua Push mới mở lại app thì
    offer gốc đã "bay mất" nếu không lưu lại, xem §5.2 tài liệu gốc).
  - `answer`: chuyển room sang CONNECTED (TTL nới ra 6h), `ClearPendingOffer(m.From)`.
  - `ice-candidate`: chỉ forward, không chạm state.
  - `call-end`/`call-reject`: đọc room trước khi xoá (lấy participants/thời điểm bắt đầu), ghi
    1 dòng bền vững vào `call_history`, `ClearPendingOffer` cho toàn bộ participants, rồi forward
    cho phía còn lại.
  - `Hub.RejectCall(roomID, fromUserID)`: fallback REST (`POST /calls/:roomId/reject`) cho cùng
    logic reject — dùng khi Client không có WS sống để tự gửi `call-reject` (app bị kill, quyết
    định Decline đến từ code native Android ngoài Flutter engine, xem
    `app/android/.../CallRejectNativeHandler.kt`).
- **Bảo mật:** field `from` trong message luôn bị override bằng userID đã xác thực qua JWT lúc
  upgrade WebSocket — Client gửi `from` gì cũng bị ghi đè, chống giả mạo danh tính người gọi.

## internal/api

`gin.Engine` với 1 middleware `RequireAuth()` áp cho mọi route trừ `/auth/dev-login`. TURN
credential (`handlers_turn.go`) dùng đúng cơ chế `use-auth-secret` chuẩn của coturn: username =
`"{expiry_unix}:{userId}"`, password = `base64(HMAC-SHA1(secret, username))` — không gọi API
coturn, không lưu credential riêng, coturn tự verify vì cùng biết secret.

## cmd/server/main.go

Wire theo thứ tự: config → Postgres (+ migrate) → Redis → repositories → auth/push → Signaling
Hub (chạy `Run(ctx)` trong goroutine riêng để lắng nghe Pub/Sub) → Gin router → HTTP server với
graceful shutdown qua `signal.NotifyContext` (SIGINT/SIGTERM).
