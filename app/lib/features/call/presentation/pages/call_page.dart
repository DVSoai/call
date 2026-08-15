import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../bloc/call_bloc.dart';

/// 1 màn hình duy nhất cho cả 3 trạng thái gọi (outgoing/incoming/in-call)
/// — CallBloc là state machine chung, page chỉ đổi UI theo state.status.
/// Điều hướng vào/ra màn hình này do app.dart lắng nghe CallBloc ở app
/// root quyết định (status != idle => push, status == idle => pop).
class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  bool _renderersReady = false;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (mounted) setState(() => _renderersReady = true);
  }

  void _syncRenderers(CallBloc bloc) {
    if (!_renderersReady) return;
    if (_localRenderer.srcObject != bloc.localStream) {
      _localRenderer.srcObject = bloc.localStream;
    }
    if (_remoteRenderer.srcObject != bloc.remoteStream) {
      _remoteRenderer.srcObject = bloc.remoteStream;
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) => _syncRenderers(context.read<CallBloc>()),
      builder: (context, state) {
        // failure/ended cũng cho pop — chỉ chặn back khi thực sự đang gọi
        // (idle/failure/ended đều là "không có cuộc gọi sống"), tránh kẹt
        // màn hình đen không thoát ra được khi getUserMedia/kết nối lỗi.
        // Pop xong vẫn phải dispatch endRequested để reset CallBloc về idle
        // — nếu không GoRouter.redirect thấy status vẫn != idle sẽ đẩy
        // ngay trở lại /call (xem app_router.dart).
        final canLeave =
            state.status == CallStatus.idle || state.status == CallStatus.failure || state.status == CallStatus.ended;
        return PopScope(
          canPop: canLeave,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop && state.status != CallStatus.idle) {
              context.read<CallBloc>().add(const CallEvent.endRequested());
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(child: _buildBody(context, state)),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CallState state) {
    final isGroup = state.callMode == 'group';
    switch (state.status) {
      case CallStatus.outgoingRinging:
        return _RingingView(peerId: state.peerId ?? '', title: 'Đang gọi...');
      case CallStatus.incomingRinging:
        return isGroup
            ? const _GroupIncomingView()
            : _IncomingView(peerId: state.peerId ?? '', callType: state.callType);
      case CallStatus.connecting:
        return isGroup
            ? const _GroupConnectingView()
            : _RingingView(peerId: state.peerId ?? '', title: 'Đang kết nối...');
      case CallStatus.connected:
        return isGroup
            ? _GroupInCallView(state: state, elapsedText: _formatElapsed(state.elapsed))
            : _InCallView(
                state: state,
                localRenderer: _renderersReady ? _localRenderer : null,
                remoteRenderer: _renderersReady ? _remoteRenderer : null,
                elapsedText: _formatElapsed(state.elapsed),
              );
      case CallStatus.ended:
        return Center(
          child: Text(
            state.errorMessage ?? 'Cuộc gọi đã kết thúc',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        );
      case CallStatus.failure:
        return _ErrorView(message: state.errorMessage ?? 'Có lỗi xảy ra');
      case CallStatus.idle:
        return const SizedBox.shrink();
    }
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
              onPressed: () => context.read<CallBloc>().add(const CallEvent.endRequested()),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingingView extends StatelessWidget {
  const _RingingView({required this.peerId, required this.title});

  final String peerId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Text(peerId, style: const TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 40),
          FloatingActionButton(
            heroTag: 'end_call',
            backgroundColor: Colors.red,
            onPressed: () => context.read<CallBloc>().add(const CallEvent.endRequested()),
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }
}

class _IncomingView extends StatelessWidget {
  const _IncomingView({required this.peerId, required this.callType});

  final String peerId;
  final String callType;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.person, size: 48)),
          const SizedBox(height: 16),
          Text(peerId, style: const TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            callType == 'video' ? 'Cuộc gọi video đến' : 'Cuộc gọi thoại đến',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'reject_call',
                backgroundColor: Colors.red,
                onPressed: () => context.read<CallBloc>().add(const CallEvent.rejectRequested()),
                child: const Icon(Icons.call_end),
              ),
              const SizedBox(width: 32),
              FloatingActionButton(
                heroTag: 'accept_call',
                backgroundColor: Colors.green,
                onPressed: () => context.read<CallBloc>().add(const CallEvent.acceptRequested()),
                child: const Icon(Icons.call),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hiện bottom sheet liệt kê thiết bị audio output thật (loa ngoài, tai
/// nghe áp tai, tai nghe dây, Bluetooth...) — không chỉ toggle nhị phân
/// loa/tai như trước, để user chọn đúng thiết bị đang đeo (vd. đang đeo tai
/// nghe Bluetooth nhưng muốn chuyển sang loa ngoài, hoặc ngược lại).
Future<void> _showAudioOutputPicker(BuildContext context) async {
  final bloc = context.read<CallBloc>();
  final outputs = await bloc.listAudioOutputs();
  if (!context.mounted) return;

  if (outputs.isEmpty) {
    // Không liệt kê được thiết bị (hiếm, tuỳ OS/thời điểm gọi) — fallback
    // về toggle nhị phân loa/tai để không kẹt user không bấm được gì.
    bloc.add(const CallEvent.speakerToggled());
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: outputs
            .map((d) => ListTile(
                  leading: Icon(_iconForAudioOutput(d.label)),
                  title: Text(_labelForAudioOutput(d.label)),
                  onTap: () {
                    bloc.add(CallEvent.audioOutputSelected(
                      deviceId: d.deviceId,
                      isSpeaker: _isSpeakerOutput(d.label),
                    ));
                    Navigator.of(sheetContext).pop();
                  },
                ))
            .toList(),
      ),
    ),
  );
}

bool _isSpeakerOutput(String label) => label.toLowerCase().contains('speaker');

IconData _iconForAudioOutput(String label) {
  final l = label.toLowerCase();
  if (l.contains('speaker')) return Icons.volume_up;
  if (l.contains('bluetooth')) return Icons.bluetooth_audio;
  if (l.contains('wired') || l.contains('headset') || l.contains('headphone')) return Icons.headset;
  return Icons.hearing;
}

String _labelForAudioOutput(String label) {
  final l = label.toLowerCase();
  if (l.contains('speaker')) return 'Loa ngoài';
  if (l.contains('bluetooth')) return label.isNotEmpty ? label : 'Bluetooth';
  if (l.contains('wired') || l.contains('headset') || l.contains('headphone')) return 'Tai nghe';
  if (l.contains('earpiece') || l.contains('receiver')) return 'Tai nghe thoại (áp tai)';
  return label.isNotEmpty ? label : 'Thiết bị âm thanh';
}

/// Group Call v1 chỉ audio (xem docs/CALL_SYSTEM.md §7) — không có tên hiển
/// thị người mời (CallState chỉ giữ userID, chưa tra display name), UI cố
/// tình chung chung "Cuộc gọi nhóm" thay vì hiện UUID cho user.
class _GroupConnectingView extends StatelessWidget {
  const _GroupConnectingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.groups, size: 48)),
          const SizedBox(height: 16),
          const Text('Đang kết nối cuộc gọi nhóm...', style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 40),
          FloatingActionButton(
            heroTag: 'end_call',
            backgroundColor: Colors.red,
            onPressed: () => context.read<CallBloc>().add(const CallEvent.endRequested()),
            child: const Icon(Icons.call_end),
          ),
        ],
      ),
    );
  }
}

class _GroupIncomingView extends StatelessWidget {
  const _GroupIncomingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(radius: 48, child: Icon(Icons.groups, size: 48)),
          const SizedBox(height: 16),
          const Text('Cuộc gọi nhóm đến', style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: 'reject_call',
                backgroundColor: Colors.red,
                onPressed: () => context.read<CallBloc>().add(const CallEvent.rejectRequested()),
                child: const Icon(Icons.call_end),
              ),
              const SizedBox(width: 32),
              FloatingActionButton(
                heroTag: 'accept_call',
                backgroundColor: Colors.green,
                onPressed: () => context.read<CallBloc>().add(const CallEvent.acceptRequested()),
                child: const Icon(Icons.call),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Group call — audio thì hiện danh sách avatar như trước (chỉ cần biết ai
/// ĐANG publish, không cần renderer); video thì hiện lưới RTCVideoView, mỗi
/// participant 1 renderer riêng, tạo/huỷ theo đúng groupRemoteStreams đang
/// có (không dùng participantIds — đó là danh sách MỜI, có thể có người
/// chưa join). Camera của chính mình nổi góc trên phải, giống _InCallView.
class _GroupInCallView extends StatefulWidget {
  const _GroupInCallView({required this.state, required this.elapsedText});

  final CallState state;
  final String elapsedText;

  @override
  State<_GroupInCallView> createState() => _GroupInCallViewState();
}

class _GroupInCallViewState extends State<_GroupInCallView> {
  final Map<String, RTCVideoRenderer> _renderers = {};
  final Set<String> _pendingInit = {};
  final _localRenderer = RTCVideoRenderer();
  bool _localReady = false;

  @override
  void initState() {
    super.initState();
    _initLocalRenderer();
  }

  Future<void> _initLocalRenderer() async {
    await _localRenderer.initialize();
    if (mounted) setState(() => _localReady = true);
  }

  // RTCVideoRenderer.initialize() là async — không thể tạo renderer ngay
  // trong build(). Đánh dấu userId đang khởi tạo (_pendingInit) để tránh tạo
  // trùng nếu build() chạy lại trước khi initialize() xong (vd. do ticker
  // mỗi giây), rồi setState khi renderer sẵn sàng để build() lần sau vẽ
  // được RTCVideoView cho participant đó.
  void _ensureRenderer(String userId, MediaStream stream) {
    final existing = _renderers[userId];
    if (existing != null) {
      if (existing.srcObject != stream) existing.srcObject = stream;
      return;
    }
    if (_pendingInit.contains(userId)) return;
    _pendingInit.add(userId);
    _createRenderer(userId, stream);
  }

  Future<void> _createRenderer(String userId, MediaStream stream) async {
    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    renderer.srcObject = stream;
    _pendingInit.remove(userId);
    if (!mounted) {
      await renderer.dispose();
      return;
    }
    setState(() => _renderers[userId] = renderer);
  }

  void _pruneRenderers(Set<String> activeUserIds) {
    final staleIds = _renderers.keys.where((id) => !activeUserIds.contains(id)).toList();
    for (final id in staleIds) {
      _renderers.remove(id)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final r in _renderers.values) {
      r.dispose();
    }
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CallBloc>();
    final isVideo = widget.state.callType == 'video';
    final streams = bloc.groupRemoteStreams;

    if (isVideo) {
      for (final entry in streams.entries) {
        _ensureRenderer(entry.key, entry.value);
      }
      _pruneRenderers(streams.keys.toSet());
      if (_localReady && _localRenderer.srcObject != bloc.localStream) {
        _localRenderer.srcObject = bloc.localStream;
      }
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 120, left: 24, right: 24),
          child: Column(
            children: [
              Text(widget.elapsedText, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: streams.isEmpty
                    ? const Center(
                        child: Text('Đang chờ người khác tham gia...', style: TextStyle(color: Colors.white70)),
                      )
                    : isVideo
                        ? _VideoGrid(renderers: _renderers, userIds: streams.keys.toList())
                        : Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: streams.keys.map((_) => const _ParticipantAvatar()).toList(),
                          ),
              ),
            ],
          ),
        ),
        if (isVideo && _localReady)
          Positioned(
            top: 16,
            right: 16,
            width: 100,
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          // LayoutBuilder lấy đúng width thật đang có — dùng làm minWidth để
          // Row vẫn canh giữa bình thường khi đủ chỗ (giống trước), nhưng
          // bọc SingleChildScrollView để KHÔNG BAO GIỜ tràn cứng
          // (RenderFlex overflow) nếu màn hình/emulator hẹp bất thường —
          // lúc đó cho cuộn ngang thay vì crash.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: widget.state.isMuted ? Icons.mic_off : Icons.mic,
                      onPressed: () => context.read<CallBloc>().add(const CallEvent.muteToggled()),
                    ),
                    const SizedBox(width: 16),
                    _ControlButton(
                      icon: widget.state.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                      onPressed: () => _showAudioOutputPicker(context),
                    ),
                    const SizedBox(width: 16),
                    if (isVideo)
                      _ControlButton(
                        icon: widget.state.isCameraOff ? Icons.videocam_off : Icons.videocam,
                        onPressed: () => context.read<CallBloc>().add(const CallEvent.cameraToggled()),
                      ),
                    if (isVideo) const SizedBox(width: 16),
                    if (isVideo)
                      _ControlButton(
                        icon: Icons.cameraswitch,
                        onPressed: () => context.read<CallBloc>().add(const CallEvent.switchCameraRequested()),
                      ),
                    if (isVideo) const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'hangup',
                      backgroundColor: Colors.red,
                      onPressed: () => context.read<CallBloc>().add(const CallEvent.endRequested()),
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lưới video participant — số cột tăng dần theo số người để ô video không
/// bị quá nhỏ khi ít người (1 người: full, 2-4 người: 2 cột, >4: 3 cột).
/// Participant chưa có renderer sẵn sàng (đang initialize() dở) hiện avatar
/// tạm thay vì để trống.
class _VideoGrid extends StatelessWidget {
  const _VideoGrid({required this.renderers, required this.userIds});

  final Map<String, RTCVideoRenderer> renderers;
  final List<String> userIds;

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = userIds.length <= 1 ? 1 : (userIds.length <= 4 ? 2 : 3);
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3 / 4,
      ),
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        final renderer = renderers[userIds[index]];
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.white10,
            child: renderer == null
                ? const Center(child: _ParticipantAvatar())
                : RTCVideoView(renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
          ),
        );
      },
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  const _ParticipantAvatar();

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 32,
      backgroundColor: Colors.white24,
      child: Icon(Icons.person, color: Colors.white, size: 32),
    );
  }
}

class _InCallView extends StatelessWidget {
  const _InCallView({
    required this.state,
    required this.localRenderer,
    required this.remoteRenderer,
    required this.elapsedText,
  });

  final CallState state;
  final RTCVideoRenderer? localRenderer;
  final RTCVideoRenderer? remoteRenderer;
  final String elapsedText;

  @override
  Widget build(BuildContext context) {
    final isVideo = state.callType == 'video';
    return Stack(
      children: [
        if (isVideo && remoteRenderer != null)
          Positioned.fill(child: RTCVideoView(remoteRenderer!, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover))
        else
          const Center(child: CircleAvatar(radius: 56, child: Icon(Icons.person, size: 56))),
        if (isVideo && localRenderer != null)
          Positioned(
            top: 16,
            right: 16,
            width: 100,
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: RTCVideoView(localRenderer!, mirror: true),
            ),
          ),
        Positioned(
          top: 16,
          left: 16,
          child: Text(
            elapsedText,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        // Phụ đề dịch (Translated Call, §8) — chỉ hiện khi user đã bật và
        // có câu vừa dịch xong, tự biến mất khi subtitleText về null (câu
        // im lặng/tắt phụ đề) thay vì để 1 khung trống chiếm chỗ.
        if (state.subtitlesEnabled && state.subtitleText != null && state.subtitleText!.isNotEmpty)
          Positioned(
            left: 24,
            right: 24,
            bottom: 108,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                state.subtitleText!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          // Xem _GroupInCallView — cùng lý do bọc LayoutBuilder +
          // SingleChildScrollView: canh giữa bình thường khi đủ chỗ, không
          // bao giờ tràn cứng khi màn hình hẹp (video call có tới 5 nút).
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: state.isMuted ? Icons.mic_off : Icons.mic,
                      onPressed: () => context.read<CallBloc>().add(const CallEvent.muteToggled()),
                    ),
                    const SizedBox(width: 16),
                    _ControlButton(
                      icon: state.isSpeakerOn ? Icons.volume_up : Icons.hearing,
                      onPressed: () => _showAudioOutputPicker(context),
                    ),
                    const SizedBox(width: 16),
                    if (isVideo)
                      _ControlButton(
                        icon: state.isCameraOff ? Icons.videocam_off : Icons.videocam,
                        onPressed: () => context.read<CallBloc>().add(const CallEvent.cameraToggled()),
                      ),
                    if (isVideo) const SizedBox(width: 16),
                    if (isVideo)
                      _ControlButton(
                        icon: Icons.cameraswitch,
                        onPressed: () => context.read<CallBloc>().add(const CallEvent.switchCameraRequested()),
                      ),
                    if (isVideo) const SizedBox(width: 16),
                    // Phụ đề chỉ có ý nghĩa cho call 1-1 (v1, xem
                    // docs/CALL_SYSTEM.md §8) — callMode luôn 'direct' ở
                    // _InCallView (group dùng _GroupInCallView riêng) nên
                    // không cần check thêm điều kiện ở đây.
                    _ControlButton(
                      icon: state.subtitlesEnabled ? Icons.closed_caption : Icons.closed_caption_off,
                      onPressed: () => context.read<CallBloc>().add(const CallEvent.subtitlesToggled()),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton(
                      heroTag: 'hangup',
                      backgroundColor: Colors.red,
                      onPressed: () => context.read<CallBloc>().add(const CallEvent.endRequested()),
                      child: const Icon(Icons.call_end),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.white24,
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onPressed),
    );
  }
}
