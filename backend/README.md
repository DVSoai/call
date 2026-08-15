# callserver

Signaling server cho hệ thống Call (Audio/Video) — Golang + Gin. Xem kiến trúc đầy đủ ở
[`../docs/CALL_SYSTEM.md`](../docs/CALL_SYSTEM.md) và giải thích thiết kế từng package ở
[`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Chạy thử (local)

```bash
docker compose up -d          # Postgres (5434) + Redis (6380) + coturn (3478)
cp .env.example .env
go mod tidy
go run ./cmd/server
```

Server chạy ở `http://localhost:8080`. Kiểm tra nhanh: `curl http://localhost:8080/healthz` → `200`.

## Test bằng curl

```bash
# 1. Đăng nhập (dev-login, chưa có OTP thật)
curl -s -X POST http://localhost:8080/auth/dev-login \
  -H "Content-Type: application/json" \
  -d '{"phone":"0900000001"}' | tee /tmp/login.json

TOKEN=$(jq -r .token /tmp/login.json)

# 2. Lấy TURN credential
curl -s http://localhost:8080/turn-credentials -H "Authorization: Bearer $TOKEN"

# 3. Đăng ký push token
curl -s -X POST http://localhost:8080/devices/register-push-token \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"platform":"android","pushToken":"fake-token-123"}'

# 4. Cập nhật ngôn ngữ nghe ưu tiên
curl -s -X PUT http://localhost:8080/users/preferred-language \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"language":"en"}'

# 5. Lịch sử cuộc gọi
curl -s http://localhost:8080/calls/history -H "Authorization: Bearer $TOKEN"
```

## Test signaling 2 tab trình duyệt (không cần Flutter)

Mở `test/client.html` (double-click hoặc qua static server bất kỳ) ở **2 tab**:

1. Tab A: nhập số điện thoại A, bấm "Login + Connect WS".
2. Tab B: nhập số điện thoại B, bấm "Login + Connect WS".
3. Tab A: chọn type `offer`, dán `userId` của tab B vào ô `to`, bấm Gửi.
4. Tab B sẽ thấy message xuất hiện ở log — copy `callId` (đã tự điền), chọn type `answer`, gửi lại cho A.
5. Thử tiếp `ice-candidate`, `call-end`, `call-reject` để xem routing hoạt động đúng.

## Cấu trúc thư mục

```
cmd/server/main.go     — entrypoint, wire tất cả module
internal/config/       — đọc biến môi trường
internal/db/           — PostgreSQL: connection, migration, repository
internal/calls/        — Redis: presence + call/room state (TTL tự hết hạn)
internal/signaling/    — WebSocket Hub: message schema, client, routing
internal/auth/         — JWT sinh/verify + middleware
internal/push/         — interface Dispatcher, LogDispatcher cho giai đoạn test
internal/api/          — REST handlers + WebSocket upgrade + TURN credential
coturn/turnserver.conf — cấu hình TURN server cho giai đoạn test
docker-compose.yml     — Postgres + Redis + coturn, chạy local 1 lệnh
test/client.html       — trang test WebSocket signaling bằng trình duyệt
```

## Deploy lên VPS (gợi ý ngắn)

1. Build binary: `GOOS=linux GOARCH=amd64 go build -o callserver ./cmd/server`
2. Chạy Postgres/Redis/coturn thật (không dùng lại `docker-compose.yml` này nguyên bản — đổi
   password, tắt `allow-loopback-peers` trong `coturn/turnserver.conf`, bật TLS cho coturn).
3. Set biến môi trường thật (không dùng giá trị trong `.env.example`), đặc biệt `JWT_SECRET`
   và `TURN_SECRET` phải là chuỗi random dài, khác giá trị dev.
4. Đặt server sau reverse proxy (nginx/caddy) hỗ trợ WebSocket upgrade (`Upgrade`/`Connection`
   header) cho path `/ws`.
