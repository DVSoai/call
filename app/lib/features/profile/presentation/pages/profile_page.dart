import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../call/presentation/pages/dev/asr_benchmark_page.dart';

/// Tab Profile — thông tin tài khoản + lối vào Lịch sử cuộc gọi (không
/// tách tab riêng để giữ đúng 4 tab: Home/Message/Contacts/Profile) +
/// logout.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 8),
          Center(
            child: Text(
              user?.phone ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Lịch sử cuộc gọi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/history'),
          ),
          const Divider(height: 1),
          // Đo baseline độ trễ ASR (docs/CALL_SYSTEM.md §8.6c) — công cụ dev,
          // xoá khỏi ProfilePage khi đo xong, không phải tính năng sản phẩm.
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: const Text('Đo thử ASR (dev)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AsrBenchmarkPage()),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
            onTap: () => context.read<AuthBloc>().add(const AuthEvent.loggedOut()),
          ),
        ],
      ),
    );
  }
}
