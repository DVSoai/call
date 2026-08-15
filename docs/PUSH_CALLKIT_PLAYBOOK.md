# Playbook: Push Notification + CallKit cho app Call (Flutter + backend tự viết)

> File này KHÔNG phải tài liệu kiến trúc của riêng dự án `call_video` — đây là bản tổng hợp
> pattern/lệnh/gotcha đã áp dụng thành công, để tái sử dụng khi làm 1 dự án Call/Video khác (kể cả
> khác tech stack backend). Đưa file này cho Claude ở dự án mới để dựng lại nhanh, không phải dò
> lại từng bước. Giả định: signaling qua WebSocket tự viết (không phải service bên thứ 3 kiểu
> Agora/Twilio), backend có thể gửi push, client Flutter build cho Android trước (iOS cần thêm
> Apple Developer Program — xem mục cuối).

## 1. Vấn đề cần giải + kiến trúc tổng quan

WebSocket sống chỉ hoạt động khi app đang chạy. 3 vấn đề phải giải quyết cùng lúc:

1. **App bị kill / backgrounded lâu → WS chết** → cần push (FCM/APNs) để đánh thức.
2. **Offer signaling chỉ forward sống 1 lần** → nếu callee offline lúc offer tới, offer đó "biến
   mất". Callee được đánh thức qua push xong reconnect thì không còn gì để answer, TRỪ KHI server
   lưu lại offer và tự gửi lại lúc callee reconnect.
3. **Quyết định Decline lúc app bị kill hẳn không có Dart nào chạy để gửi phản hồi qua WS** — cần
   xử lý native, bắn thẳng 1 request REST (không cần WS) để báo caller.

Kiến trúc chốt (đã chạy được thật, nhánh Android):

```
Server nhận offer → lưu OfferSDP vào call state + đánh dấu "pending offer cho calleeID"
                  → callee online? forward sống qua WS : gửi FCM (data message, priority=high)

Client (background handler, Flutter engine riêng biệt, chạy cả khi app đã kill)
  → nhận FCM data message → FlutterCallkitIncoming.showCallkitIncoming() → hiện UI cuộc gọi đến
    kiểu native (không phải notification thường)

User bấm Accept → app resume/cold-start → CallBloc connect lại WS
  → Server thấy callee vừa connect, có "pending offer" đang chờ → tự redeliver offer y hệt lúc
    forward sống (Hub.register() → redeliverPendingOffer)
  → CallBloc nhận offer đã được đánh dấu trước "auto-accept" (do accept trên CallKit) → tự accept
    luôn, không hỏi lại user

User bấm Decline lúc app CÒN chạy (chỉ backgrounded) → Dart xử lý bình thường, gửi call-reject qua
  WS đang sống.

User bấm Decline lúc app ĐÃ KILL HẲN → flutter_callkit_incoming xử lý native, không mở lại app →
  cần 1 handler NATIVE riêng (không qua Flutter) bắn thẳng HTTP POST /calls/:id/reject tới backend.
```

**Quyết định phạm vi quan trọng:** KHÔNG viết lại toàn bộ WebRTC/signaling bằng native để "nhận
call tức thời từ lúc tap thông báo" — chi phí (duplicate toàn bộ PeerConnection/signaling bằng
Kotlin+Swift, maintain 2 bộ code mãi mãi) lớn hơn nhiều lợi ích (rút vài trăm ms tới 1-2s). Native
chỉ nên làm những việc KHÔNG cần Flutter engine và KHÔNG cần media: hiện UI cuộc gọi đến, và các
hành động fire-and-forget đơn giản (reject). Accept vẫn đi qua resume app + reconnect Dart.

## 2. Setup Firebase (từ số 0)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

**Gotcha Windows:** npm global bin (`%APPDATA%\npm`) và Dart pub global bin
(`%LOCALAPPDATA%\Pub\Cache\bin`) thường KHÔNG có sẵn trong PATH — thêm bằng
`[Environment]::SetEnvironmentVariable("Path", "$old;$newDir", "User")` (KHÔNG dùng `setx PATH`,
lệnh đó cắt PATH ở 1024 ký tự, phá PATH dài). Mở terminal mới sau khi đổi.

```bash
firebase login                       # mở browser, đăng nhập Google
firebase projects:create <id> --display-name "<name>"   # id phải unique TOÀN CẦU, hay bị trùng —
                                                          # thử thêm suffix random nếu báo đã tồn tại
cd <flutter-app-dir>
flutterfire configure --project=<id> --platforms=android -y
```

→ Sinh `lib/firebase_options.dart`, tự thêm `google-services.json` + áp plugin
`com.google.gms.google-services` vào Gradle. `google-services.json` KHÔNG phải secret, commit bình
thường được.

**Service account cho backend gọi Admin SDK:** Firebase Console → Project Settings → Service
accounts → "Generate new private key" → tải JSON → đặt trong thư mục backend, **thêm vào
.gitignore ngay** (đây MỚI là secret thật, khác `google-services.json`).

## 3. Flutter — package + version đã xác nhận hoạt động

```yaml
firebase_core: ^4.1.1
firebase_messaging: ^16.0.4
flutter_callkit_incoming: ^3.1.5   # MIT, miễn phí. v3.x dùng sealed class cho CallEvent, KHÁC
                                     # hẳn API enum "Event" ở các ví dụ/tutorial cũ trên mạng —
                                     # LUÔN đọc source thật trong pub cache trước khi code theo
                                     # docs/ví dụ cũ, kẻo build lỗi ambiguous_import/undefined.
```

**Android bắt buộc** (khác biệt so với app Flutter thường):
- `AndroidManifest.xml`: activity chính `android:launchMode="singleInstance"` (bắt buộc theo yêu
  cầu package), thêm `android:showWhenLocked="true"` + `android:turnScreenOn="true"` để hiện được
  qua màn hình khoá.
- Quyền: `POST_NOTIFICATIONS` (Android 13+), `USE_FULL_SCREEN_INTENT`.
- `firebaseMessagingBackgroundHandler` PHẢI là top-level function (không phải method trong class),
  đánh dấu `@pragma('vm:entry-point')` — chạy trên isolate riêng, độc lập hoàn toàn app đã kill hay
  chưa.

**Pattern CallKit đầy đủ (Dart side, xem `push_service.dart` gốc để copy nguyên khối):**
- Background handler: nhận FCM data message (KHÔNG dùng `notification` field, chỉ `data` — để tự
  quyết định hiển thị gì) → `showCallkitIncoming()`.
- `wireCallBloc()` gọi 1 lần lúc app khởi động (không chờ authenticated):
  - Lắng nghe `FlutterCallkitIncoming.onEvent` — switch theo sealed class
    (`CallEventActionCallAccept`/`CallEventActionCallDecline`/`CallEventActionCallTimeout`), lấy
    data qua `callKitParams.extra`/`.id` (KHÔNG phải `event.body` map như bản cũ).
  - Check `FlutterCallkitIncoming.activeCalls()` (trả `List<CallKitParams>` có typed field) lúc
    khởi động — bắt trường hợp app cold-start CHÍNH VÌ user vừa bấm Accept, onEvent có thể miss vì
    listener chưa kịp gắn.
  - **Case hay bị bỏ sót:** app chỉ bị THU NHỎ (không kill) → WS vẫn sống → offer tới thẳng qua WS
    bình thường, KHÔNG qua nhánh push/FCM ở trên → không tự hiện CallKit UI. Phải tự trigger
    `showCallkitIncoming()` ngay trong Dart khi thấy state chuyển sang incoming-ringing MÀ app
    không ở foreground (`WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed`).
  - `endAllCalls()` khi state quay về idle — dọn native state, tránh CallKit/activeCalls bị "treo".

## 4. Backend — pattern lưu & redeliver offer (áp dụng cho MỌI signaling server tự viết)

Bất kể ngôn ngữ backend gì, nếu signaling model là "forward message sống qua WS, không lưu gì cả"
(kiểu đơn giản nhất, hay là điểm khởi đầu mặc định) — PHẢI thêm:

1. Lúc nhận offer: lưu SDP kèm state room (không chỉ forward rồi quên).
2. Đánh dấu 1 marker "callee X đang có offer RINGING chờ" (TTL = TTL của trạng thái RINGING).
3. Lúc callee reconnect (bất kể lý do gì — network drop, vừa mở lại app sau khi bị push đánh
   thức...): check marker này, nếu có → redeliver offer y hệt lúc forward sống, coi như user vừa
   nhận trực tiếp.
4. Xoá marker khi room kết thúc dưới mọi hình thức (answer/reject/end/timeout) — tránh redeliver
   offer đã hết hiệu lực.

Đây LÀ pattern chung, không phụ thuộc Redis/Postgres/ngôn ngữ — chỉ cần 1 nơi lưu state có TTL.

## 5. Native reject fallback (Android) — pattern để KHÔNG phải viết lại toàn bộ signaling native

`flutter_callkit_incoming` bản Android có sẵn interface `CallkitEventCallback`
(`registerEventCallback`) — **chạy được cả khi Flutter engine chưa khởi động** (đăng ký ở
`Application.onCreate()`, không phải `MainActivity`, vì Android sẽ chạy `Application.onCreate()`
dù chỉ đánh thức process để giao 1 broadcast, không hề mở Activity nào). Đây là hook đúng chỗ để
thêm xử lý native nhẹ (không cần media/signaling đầy đủ) mà không phải fork cả plugin.

Cần thêm:
- 1 class native đọc token JWT **riêng cho native** (không đọc trực tiếp định dạng nội bộ của
  `flutter_secure_storage`, dễ vỡ khi plugin đó đổi implementation) — dùng
  `androidx.security:security-crypto` (`EncryptedSharedPreferences`), bản stable mới nhất tại thời
  điểm viết: **1.1.0** (kiểm tra lại `maven-metadata.xml` nếu làm dự án mới, version có thể đã lên
  cao hơn). Dart ghi vào qua 1 `MethodChannel` riêng mỗi khi login/logout — KHÔNG phải nguồn sự
  thật, chỉ là bản sao fire-and-forget.
- 1 class implement `CallkitEventCallback`, nhận event DECLINE → đọc `roomId` từ
  `Data.fromBundle(callData).extra["roomId"]` → bắn `HttpURLConnection` POST tới backend (chạy
  trên background thread/executor riêng, không phải main thread) — không cần OkHttp hay dependency
  gì thêm, `HttpURLConnection` chuẩn Java đủ dùng cho 1 request đơn giản.
- Backend cần 1 endpoint REST tương đương hành vi reject qua WS (không phải viết logic mới, chỉ
  expose lại logic cũ qua đường REST thay vì WS message).

**Tổ chức file native:** theo convention phổ biến (đã đối chiếu 1 project Flutter thật khác) —
`MainActivity` chỉ wiring (tạo `MethodChannel`, gọi `.setMethodCallHandler(...)`), mỗi tính năng 1
file riêng cùng package, implement `MethodChannel.MethodCallHandler` với `companion object { const
val CHANNEL = "..." }`. Không nhét logic thẳng vào `MainActivity`, kể cả khi lúc đầu chỉ có 1-2
tính năng — file main phình to rất nhanh khi thêm tính năng native thứ 3-4.

## 6. Việc CHƯA làm / để dành lần sau

- **iOS toàn bộ**: PushKit (VoIP push) + CallKit thật — cần Apple Developer Program ($99/năm) mới
  test được trên máy thật. `flutter_callkit_incoming` có sẵn phần này, chỉ chưa cấu hình/test.
- **Native accept**: cố tình KHÔNG làm — accept cần mở PeerConnection thật, không đáng đánh đổi
  chi phí duplicate signaling+WebRTC bằng native (xem mục 1).
- **`setMuted()`/`setSpeaker()` ở tầng native**: hiện điều khiển thẳng qua `flutter_webrtc` (Dart)
  vì lúc mute/loa chắc chắn app đang chạy (đang trong cuộc gọi) — không cần native.
- **`handleSystemEnd()` custom**: chưa thêm logic riêng khi OS tự kết thúc cuộc gọi (vd. Telecom
  interrupt bởi cuộc gọi SIM khác) — plugin tự dismiss notification, chưa báo backend.

## 7. Checklist nhanh khi bắt đầu dự án Call mới

- [ ] `firebase-tools` + `flutterfire_cli` cài, PATH đã fix (Windows)
- [ ] Firebase project tạo, `flutterfire configure --platforms=android`
- [ ] Service account JSON tải, gitignore ngay
- [ ] `firebase_core` + `firebase_messaging` + `flutter_callkit_incoming` (đọc source thật trong
      pub cache trước khi code theo tutorial cũ)
- [ ] AndroidManifest: `singleInstance`, `showWhenLocked`, `turnScreenOn`, `POST_NOTIFICATIONS`,
      `USE_FULL_SCREEN_INTENT`
- [ ] Backend: lưu offer + pending-offer marker + redeliver lúc reconnect (mục 4)
- [ ] Backend: implementation Dispatcher thật (FCM Go SDK hoặc tương đương), chọn qua config, giữ
      LogDispatcher làm fallback cho dev chưa setup Firebase
- [ ] Dart: background handler + wireCallBloc (onEvent + activeCalls() + case app-chỉ-thu-nhỏ)
- [ ] Native: `CallVideoApplication`/tương đương đăng ký `CallkitEventCallback`, NativeAuthBridge
      (EncryptedSharedPreferences), REST reject endpoint backend
- [ ] Test thật: kill app hẳn → gọi tới → CallKit hiện → Accept → tự nối được cuộc gọi (không hỏi
      lại). Kill app hẳn → gọi tới → Decline → caller nhận reject ngay (không phải đợi TTL hết hạn)
