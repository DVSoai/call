import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../call/presentation/bloc/call_bloc.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../bloc/chat_bloc.dart';

/// Đối số cho route /message/chat/:id — [peerId] chỉ có với conversation
/// "direct" (1-1), null với "group" vì Group Call (SFU) chưa build (xem
/// CLAUDE.md — chỉ chương 1-1 đã ổn định), nên nút gọi trong ChatPage chỉ
/// hiện khi có peerId.
class ChatPageArgs {
  final String title;
  final String? peerId;

  const ChatPageArgs({required this.title, this.peerId});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.title, this.peerId});

  final String title;
  final String? peerId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // ListView có reverse:true — cuộn tới maxScrollExtent nghĩa là user đang
  // ở TRÊN CÙNG (tin cũ nhất đã tải), lúc đó mới tải thêm tin cũ hơn.
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatBloc>().add(const ChatEvent.olderRequested());
    }
  }

  void _send() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    context.read<ChatBloc>().add(ChatEvent.sendRequested(text: text));
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<ChatBloc>().currentUserId;

    final peerId = widget.peerId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: peerId == null
            ? null
            : [
                IconButton(
                  tooltip: 'Gọi thoại',
                  icon: const Icon(Icons.call_outlined),
                  onPressed: () => context
                      .read<CallBloc>()
                      .add(CallEvent.outgoingCallRequested(calleeId: peerId, isVideo: false)),
                ),
                IconButton(
                  tooltip: 'Gọi video',
                  icon: const Icon(Icons.videocam_outlined),
                  onPressed: () => context
                      .read<CallBloc>()
                      .add(CallEvent.outgoingCallRequested(calleeId: peerId, isVideo: true)),
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state.status == ChatStatus.failure && state.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
                }
              },
              builder: (context, state) {
                if (state.status == ChatStatus.loading && state.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn nào — gửi lời chào đầu tiên!', style: TextStyle(color: Colors.black54)),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: state.messages.length + (state.loadingOlder ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final message = state.messages[index];
                    return _MessageBubble(message: message, isMine: message.senderId == currentUserId);
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessageEntity message;
  final bool isMine;

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.content),
            const SizedBox(height: 2),
            Text(
              _formatTime(message.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
