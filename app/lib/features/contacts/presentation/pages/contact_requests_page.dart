import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/contact_entity.dart';
import '../bloc/contact_requests_bloc.dart';

/// Màn hình "Lời mời kết bạn" — 2 danh sách: lời mời NGƯỜI KHÁC gửi cho
/// mình (accept/reject) và lời mời MÌNH đã gửi đi, đang chờ (huỷ được).
class ContactRequestsPage extends StatelessWidget {
  const ContactRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lời mời kết bạn'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Đã nhận'), Tab(text: 'Đã gửi')],
          ),
        ),
        body: BlocConsumer<ContactRequestsBloc, ContactRequestsState>(
          listener: (context, state) {
            if (state.status == ContactRequestsStatus.failure && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == ContactRequestsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: [
                _IncomingList(requests: state.incoming),
                _OutgoingList(requests: state.outgoing),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _IncomingList extends StatelessWidget {
  const _IncomingList({required this.requests});

  final List<ContactEntity> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('Không có lời mời nào', style: TextStyle(color: Colors.black54)));
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<ContactRequestsBloc>().add(const ContactRequestsEvent.refreshed()),
      child: ListView.separated(
        itemCount: requests.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final request = requests[index];
          final name = request.otherUser.displayName.isNotEmpty
              ? request.otherUser.displayName
              : request.otherUser.phone;
          return ListTile(
            leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
            title: Text(name),
            subtitle: Text(request.otherUser.phone),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Từ chối',
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => context
                      .read<ContactRequestsBloc>()
                      .add(ContactRequestsEvent.responded(contactId: request.id, accept: false)),
                ),
                IconButton(
                  tooltip: 'Chấp nhận',
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => context
                      .read<ContactRequestsBloc>()
                      .add(ContactRequestsEvent.responded(contactId: request.id, accept: true)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OutgoingList extends StatelessWidget {
  const _OutgoingList({required this.requests});

  final List<ContactEntity> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const Center(child: Text('Chưa gửi lời mời nào', style: TextStyle(color: Colors.black54)));
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<ContactRequestsBloc>().add(const ContactRequestsEvent.refreshed()),
      child: ListView.separated(
        itemCount: requests.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final request = requests[index];
          final name = request.otherUser.displayName.isNotEmpty
              ? request.otherUser.displayName
              : request.otherUser.phone;
          return ListTile(
            leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
            title: Text(name),
            subtitle: const Text('Đang chờ phản hồi'),
            trailing: TextButton(
              onPressed: () => context
                  .read<ContactRequestsBloc>()
                  .add(ContactRequestsEvent.outgoingCancelled(contactId: request.id)),
              child: const Text('Huỷ'),
            ),
          );
        },
      ),
    );
  }
}
