import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../call/presentation/bloc/call_bloc.dart';
import '../../../message/domain/entities/conversation_entity.dart';
import '../../../message/domain/usecases/create_conversation_usecase.dart';
import '../../../message/presentation/pages/chat_page.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/contacts_bloc.dart';

/// Tab "Danh bạ" — danh sách bạn bè đã accepted. Chỉ những người ở đây mới
/// nhắn tin/gọi được (rule "kết bạn mới nhắn tin được" — xem CLAUDE.md).
class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ'),
        actions: [
          IconButton(
            tooltip: 'Lời mời kết bạn',
            icon: const Icon(Icons.mail_outline),
            onPressed: () => context.push('/contacts/requests'),
          ),
          IconButton(
            tooltip: 'Tìm bạn theo số điện thoại',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: () => context.push('/contacts/search'),
          ),
        ],
      ),
      body: BlocConsumer<ContactsBloc, ContactsState>(
        listener: (context, state) {
          if (state.status == ContactsStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (context, state) {
          if (state.status == ContactsStatus.loading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => context.read<ContactsBloc>().add(const ContactsEvent.refreshed()),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Chưa có bạn bè nào — bấm biểu tượng thêm bạn để tìm theo số điện thoại.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => context.read<ContactsBloc>().add(const ContactsEvent.refreshed()),
            child: ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _ContactTile(contact: state.items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact});

  final ContactEntity contact;

  void _confirmRemove(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá bạn bè'),
        content: Text('Xoá ${contact.otherUser.displayName} khỏi danh sách bạn bè?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Huỷ')),
          TextButton(
            onPressed: () {
              context.read<ContactsBloc>().add(ContactsEvent.removed(contactId: contact.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Direct conversation giữa 2 contact đã accepted luôn hợp lệ (rule "kết
  // bạn mới nhắn tin được" — backend tự dedup nếu đã tồn tại, xem
  // ConversationService.Create/FindDirectBetween) nên gọi thẳng usecase
  // qua getIt, không cần dựng cả 1 Bloc chỉ cho 1 hành động bấm-là-xong.
  Future<void> _openChat(BuildContext context) async {
    final name = contact.otherUser.displayName.isNotEmpty ? contact.otherUser.displayName : contact.otherUser.phone;
    final result = await getIt<CreateConversationUseCase>().call(
      CreateConversationParams(type: ConversationType.direct, participantIds: [contact.otherUser.id]),
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))),
      (conv) => context.push(
        '/message/chat/${conv.id}',
        extra: ChatPageArgs(title: name, peerId: contact.otherUser.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = contact.otherUser.displayName.isNotEmpty ? contact.otherUser.displayName : contact.otherUser.phone;
    return ListTile(
      leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
      title: Text(name),
      subtitle: Text(contact.otherUser.phone),
      onTap: () => _openChat(context),
      onLongPress: () => _confirmRemove(context),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Nhắn tin',
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => _openChat(context),
          ),
          IconButton(
            tooltip: 'Gọi thoại',
            icon: const Icon(Icons.call_outlined),
            onPressed: () => context
                .read<CallBloc>()
                .add(CallEvent.outgoingCallRequested(calleeId: contact.otherUser.id, isVideo: false)),
          ),
          IconButton(
            tooltip: 'Gọi video',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => context
                .read<CallBloc>()
                .add(CallEvent.outgoingCallRequested(calleeId: contact.otherUser.id, isVideo: true)),
          ),
        ],
      ),
    );
  }
}
