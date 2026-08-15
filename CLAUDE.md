# call_video — Hướng dẫn cho Claude Code

Dự án Call/Video Call chuẩn trải nghiệm Messenger. Client: **Flutter**. Server: **Golang + Gin**.

Tài liệu kiến trúc gốc (nguồn sự thật cho mọi quyết định thiết kế): `docs/CALL_SYSTEM.md`.
**Luôn đọc lại tài liệu đó trước khi thay đổi kiến trúc** — đừng chỉ dựa vào file này.

## Cấu trúc repo

```
call_video/
  backend/     — Go + Gin, signaling server (chi tiết bên dưới)
  app/         — Flutter app (chưa khởi tạo, tạo khi bắt đầu phần Client)
  docs/        — tài liệu kiến trúc (CALL_SYSTEM.md)
```

## Nguyên tắc kiến trúc bắt buộc

- **Quyết định "room-ready" (chốt khi xây bản đầu):** user muốn tránh viết lại nền móng khi mở
  rộng Group Call sau này, nên toàn bộ signaling/schema đã thiết kế theo khái niệm **room** ngay
  từ đầu — `callId` = `roomId`, participants là danh sách (`[]string` ở Redis, bảng
  `call_participants` ở Postgres) thay vì cột `caller_id`/`callee_id` cố định cho 2 người. Call
  1-1 chỉ là room có đúng 2 participant. Xem `backend/ARCHITECTURE.md` mục đầu tiên.
- **Nhưng vẫn CHƯA viết SFU thật** (`pion/webrtc`, media forwarding) — chỉ phần dữ liệu/schema
  là room-ready, phần media call 1-1 vẫn đi P2P trực tiếp. Đừng thêm `pion/webrtc` cho tới khi
  thật sự bắt đầu implement Group Call — xem chương 7 trong CALL_SYSTEM.md.
- **Server KHÔNG xử lý audio/video** ở giai đoạn call 1-1. Server chỉ làm signaling (forward SDP/ICE qua WebSocket), quản lý state, push notification, TURN credential, auth, call history. Media đi P2P trực tiếp giữa 2 Client (WebRTC), qua TURN chỉ khi P2P thất bại.
- **Redis = state tạm thời** (presence, call RINGING/CONNECTED, TTL tự hết hạn, mất cũng không sao). **PostgreSQL = dữ liệu bền vững** (users, device_tokens, call_history, call_participants). Không lẫn lộn hai vai trò này.
- **Không dùng ORM** ở backend — dùng `jackc/pgx` thuần, tự viết migration/repository.
- Roadmap đã chốt: **(1) Call 1-1 → (2) Group Call (SFU) → (3) Translated Call**. Không nhảy cóc triển khai engine SFU/chương 8 khi chương hiện tại (1-1) chưa ổn định — trừ khi user yêu cầu rõ ràng.

## Backend (Go) — quy ước code

- Module path: `callserver` (xem `backend/go.mod`).
- Cấu trúc package cố định theo `docs/CALL_SYSTEM.md` §4.6:
  `cmd/server`, `internal/config`, `internal/db`, `internal/calls`, `internal/signaling`, `internal/auth`, `internal/push`, `internal/api`.
- Push notification: code qua interface `push.Dispatcher`. Giai đoạn test dùng `LogDispatcher` (chỉ log ra console) — **không** gọi FCM/APNs thật cho tới khi có tài khoản Firebase + Apple Developer Program thật. Khi cần nối thật, chỉ thêm implementation mới, không sửa Hub hay module khác.
- Message signaling luôn theo đúng schema JSON đã chốt trong CALL_SYSTEM.md §4.1 (`type/from/to/callId/payload`). Không tự ý đổi field name.
- TURN credential dùng cơ chế shared-secret chuẩn coturn (`use-auth-secret`, HMAC-SHA1 time-limited) — không lưu danh sách credential riêng, không gọi API coturn.
- Giữ error handling rõ ràng nhưng không over-engineer: không thêm retry/circuit-breaker/validation cho case không xảy ra trong luồng call 1-1.
- Test nhanh không cần Flutter: `backend/test/client.html` (WebSocket 2-tab test).
- `docker-compose.yml` (Postgres 5434, Redis 6380) dùng port khác mặc định để chạy song song được với project Go khác trên cùng máy (vd. `strongbody-api` chiếm Postgres 5433/Redis 6379).

## Khi thêm tính năng mới

Trước khi code, xác định tính năng thuộc chương nào trong CALL_SYSTEM.md (1-1 / Group Call / Translated Call) và chỉ implement đúng phạm vi chương đó. Nếu tài liệu chưa có mục tương ứng, hỏi lại user thay vì tự suy diễn kiến trúc.
