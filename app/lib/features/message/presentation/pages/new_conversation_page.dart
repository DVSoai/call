import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../contacts/domain/entities/contact_entity.dart';
import '../../../contacts/presentation/bloc/contacts_bloc.dart';
import '../bloc/new_conversation_bloc.dart';
import 'chat_page.dart';

/// Chọn bạn bè (đã accepted — nguồn danh sách từ [ContactsBloc], đúng rule
/// "kết bạn mới nhắn tin được") để bắt đầu hội thoại. Chọn 1 người → tạo
/// direct; từ 2 người trở lên → tạo group (hiện thêm ô tên nhóm).
class NewConversationPage extends StatefulWidget {
  const NewConversationPage({super.key});

  @override
  State<NewConversationPage> createState() => _NewConversationPageState();
}

class _NewConversationPageState extends State<NewConversationPage> {
  final _groupNameController = TextEditingController();

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắn tin mới')),
      body: BlocListener<NewConversationBloc, NewConversationState>(
        listener: (context, state) {
          if (state.status == NewConversationStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
          if (state.status == NewConversationStatus.success && state.created != null) {
            final currentUserId = context.read<AuthBloc>().state.user?.id ?? '';
            final conv = state.created!;
            context.pushReplacement(
              '/message/chat/${conv.id}',
              extra: ChatPageArgs(title: conv.displayTitle(currentUserId), peerId: conv.peerIdFor(currentUserId)),
            );
          }
        },
        child: Column(
          children: [
            BlocBuilder<NewConversationBloc, NewConversationState>(
              buildWhen: (previous, current) => previous.selectedUserIds != current.selectedUserIds,
              builder: (context, state) {
                if (state.selectedUserIds.length < 2) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _groupNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nhóm (tuỳ chọn)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        context.read<NewConversationBloc>().add(NewConversationEvent.groupNameChanged(value)),
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<ContactsBloc, ContactsState>(
                builder: (context, contactsState) {
                  if (contactsState.status == ContactsStatus.loading && contactsState.items.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (contactsState.items.isEmpty) {
                    return const Center(
                      child: Text('Chưa có bạn bè nào để nhắn tin', style: TextStyle(color: Colors.black54)),
                    );
                  }
                  return ListView.builder(
                    itemCount: contactsState.items.length,
                    itemBuilder: (context, index) => _ContactCheckTile(contact: contactsState.items[index]),
                  );
                },
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.all(16),
              child: BlocBuilder<NewConversationBloc, NewConversationState>(
                builder: (context, state) {
                  return FilledButton(
                    onPressed: state.selectedUserIds.isEmpty || state.status == NewConversationStatus.submitting
                        ? null
                        : () => context.read<NewConversationBloc>().add(const NewConversationEvent.submitted()),
                    child: state.status == NewConversationStatus.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(state.selectedUserIds.length > 1 ? 'Tạo nhóm' : 'Bắt đầu nhắn tin'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCheckTile extends StatelessWidget {
  const _ContactCheckTile({required this.contact});

  final ContactEntity contact;

  @override
  Widget build(BuildContext context) {
    final name = contact.otherUser.displayName.isNotEmpty ? contact.otherUser.displayName : contact.otherUser.phone;
    return BlocBuilder<NewConversationBloc, NewConversationState>(
      buildWhen: (previous, current) => previous.selectedUserIds != current.selectedUserIds,
      builder: (context, state) {
        final selected = state.selectedUserIds.contains(contact.otherUser.id);
        return CheckboxListTile(
          value: selected,
          onChanged: (_) =>
              context.read<NewConversationBloc>().add(NewConversationEvent.contactToggled(contact.otherUser.id)),
          secondary: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
          title: Text(name),
          subtitle: Text(contact.otherUser.phone),
        );
      },
    );
  }
}
