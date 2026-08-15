import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../call/presentation/bloc/call_bloc.dart';

/// Màn hình chính sau đăng nhập — nhập userId đối phương để gọi thử (chưa
/// có danh bạ/tìm-kiếm-theo-số-điện-thoại — xem tab Danh bạ, hiện là
/// placeholder). Logout/lịch sử cuộc gọi nằm ở tab Cá nhân.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _calleeController = TextEditingController();
  bool _isVideo = true;

  @override
  void dispose() {
    _calleeController.dispose();
    super.dispose();
  }

  void _startCall() {
    final calleeId = _calleeController.text.trim();
    if (calleeId.isEmpty) return;
    context.read<CallBloc>().add(CallEvent.outgoingCallRequested(calleeId: calleeId, isVideo: _isVideo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('call_video')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Gọi thử', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Dán userId của tài khoản khác (đăng nhập ở 1 máy/tab khác) để gọi thử — '
              'chưa có danh bạ/tìm theo số điện thoại ở bản này.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _calleeController,
              decoration: const InputDecoration(labelText: 'userId người nhận', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Video'),
                Switch(value: _isVideo, onChanged: (v) => setState(() => _isVideo = v)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startCall,
              icon: Icon(_isVideo ? Icons.videocam : Icons.call),
              label: const Text('Gọi'),
            ),
          ],
        ),
      ),
    );
  }
}
