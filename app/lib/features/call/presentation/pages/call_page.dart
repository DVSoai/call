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
    switch (state.status) {
      case CallStatus.outgoingRinging:
        return _RingingView(peerId: state.peerId ?? '', title: 'Đang gọi...');
      case CallStatus.incomingRinging:
        return _IncomingView(peerId: state.peerId ?? '', callType: state.callType);
      case CallStatus.connecting:
        return _RingingView(peerId: state.peerId ?? '', title: 'Đang kết nối...');
      case CallStatus.connected:
        return _InCallView(
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: state.isMuted ? Icons.mic_off : Icons.mic,
                onPressed: () => context.read<CallBloc>().add(const CallEvent.muteToggled()),
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
              FloatingActionButton(
                heroTag: 'hangup',
                backgroundColor: Colors.red,
                onPressed: () => context.read<CallBloc>().add(const CallEvent.endRequested()),
                child: const Icon(Icons.call_end),
              ),
            ],
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
