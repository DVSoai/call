import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/call_history_entry.dart';
import '../bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử cuộc gọi')),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          final bloc = context.read<HistoryBloc>();
          final items = state.items ?? const <CallHistoryEntry>[];

          if (state.status == HistoryStatus.loading && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HistoryStatus.failure && items.isEmpty) {
            return Center(child: Text(state.errorMessage ?? 'Có lỗi xảy ra'));
          }
          if (items.isEmpty) {
            return const Center(child: Text('Chưa có cuộc gọi nào'));
          }

          return EasyRefresh(
            controller: bloc.refreshController,
            onRefresh: () => bloc.add(const HistoryEvent.refreshed()),
            onLoad: () => bloc.add(const HistoryEvent.loadMoreRequested()),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _HistoryTile(entry: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});

  final CallHistoryEntry entry;

  IconData get _icon {
    if (entry.status == CallHistoryStatus.missed) return Icons.call_missed;
    if (entry.status == CallHistoryStatus.rejected) return Icons.call_missed_outgoing;
    return entry.callType == 'video' ? Icons.videocam : Icons.call;
  }

  String _formatTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(_icon)),
      title: Text(entry.participants.join(', ')),
      subtitle: Text('${entry.status.label} • ${_formatTime(entry.startedAt)}'),
      trailing: Icon(entry.callType == 'video' ? Icons.videocam_outlined : Icons.call_outlined),
    );
  }
}
