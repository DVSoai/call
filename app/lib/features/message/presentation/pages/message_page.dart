import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/conversation_entity.dart';
import '../bloc/conversations_bloc.dart';
import 'chat_page.dart';

/// Tab "Tin nhắn" — danh sách hội thoại (1-1 và group), mới nhất trước.
/// FAB mở màn hình chọn bạn bè để bắt đầu hội thoại mới (xem
/// new_conversation_page.dart).
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthBloc>().state.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Tin nhắn')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/message/new'),
        child: const Icon(Icons.edit_outlined),
      ),
      body: BlocConsumer<ConversationsBloc, ConversationsState>(
        listener: (context, state) {
          if (state.status == ConversationsStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          final bloc = context.read<ConversationsBloc>();
          final items = state.items ?? const <ConversationEntity>[];

          if (state.status == ConversationsStatus.loading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return EasyRefresh(
              controller: bloc.refreshController,
              onRefresh: () => bloc.add(const ConversationsEvent.refreshed()),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Chưa có hội thoại nào — bấm nút bút chì để bắt đầu nhắn tin với bạn bè.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return EasyRefresh(
            controller: bloc.refreshController,
            onRefresh: () => bloc.add(const ConversationsEvent.refreshed()),
            onLoad: () => bloc.add(const ConversationsEvent.loadMoreRequested()),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _ConversationTile(
                conversation: items[index],
                currentUserId: currentUserId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.currentUserId});

  final ConversationEntity conversation;
  final String currentUserId;

  String _formatTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final title = conversation.displayTitle(currentUserId);
    return ListTile(
      leading: CircleAvatar(
        child: Icon(conversation.type == ConversationType.group ? Icons.group : Icons.person),
      ),
      title: Text(title),
      subtitle: Text(
        conversation.lastMessagePreview ?? 'Chưa có tin nhắn nào',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conversation.lastMessageAt != null ? Text(_formatTime(conversation.lastMessageAt!)) : null,
      onTap: () => context.push(
        '/message/chat/${conversation.id}',
        extra: ChatPageArgs(
          title: title,
          peerId: conversation.peerIdFor(currentUserId),
          participantIds: conversation.groupParticipantIdsFor(currentUserId),
        ),
      ),
    );
  }
}
