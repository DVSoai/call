import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../call/presentation/pages/dev/asr_benchmark_page.dart';
import '../../../translation/data/services/model_download_service.dart';

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
          // Ngôn ngữ NGHE (Translated Call, docs/CALL_SYSTEM.md §8) — v1 chỉ
          // Việt/Anh, khớp đúng 2 model dịch đã hỗ trợ (ModelDownloadService).
          ListTile(
            leading: const Icon(Icons.translate),
            title: const Text('Ngôn ngữ nghe'),
            subtitle: Text(_languageLabel(user?.preferredLanguage ?? 'vi')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguagePicker(context, user?.preferredLanguage ?? 'vi'),
          ),
          const Divider(height: 1),
          // Tải trước model dịch (dev, để test) — bình thường model chỉ âm
          // thầm tải lúc bấm nút CC trong cuộc gọi thật (không hiện dialog,
          // xem CallBloc._onSubtitlesToggled). Cái này CHỦ ĐỘNG tải + báo
          // tiến trình, chỉ để user test không phải chờ giữa cuộc gọi —
          // không phải hành vi của tính năng thật, xoá khi test xong.
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('Tải trước model dịch (dev)'),
            subtitle: const Text('Tải sẵn 2 chiều Việt-Anh để test, không phải chờ lúc bật phụ đề'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _downloadModelsForTesting(context),
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

String _languageLabel(String code) => switch (code) {
      'en' => 'Tiếng Anh',
      _ => 'Tiếng Việt',
    };

/// Tải cả 2 hướng vi-en/en-vi (whisper+vad dùng chung, tự bỏ qua nếu đã tải
/// — xem ModelDownloadService._ensureFile) — có dialog tiến trình vì đây là
/// hành động user CHỦ ĐỘNG bấm để test, khác lúc bật CC thật (âm thầm).
Future<void> _downloadModelsForTesting(BuildContext context) async {
  final service = getIt<ModelDownloadService>();
  final progress = ValueNotifier<double>(0);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Đang tải model dịch...'),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (_, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: value),
            const SizedBox(height: 12),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    ),
  );

  try {
    await service.ensurePipelineConfig(
      sourceLanguage: 'vi',
      targetLanguage: 'en',
      onProgress: (p) => progress.value = p / 2,
    );
    await service.ensurePipelineConfig(
      sourceLanguage: 'en',
      targetLanguage: 'vi',
      onProgress: (p) => progress.value = 0.5 + p / 2,
    );
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tải xong model dịch')));
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tải model lỗi: $e')));
  }
}

Future<void> _showLanguagePicker(BuildContext context, String current) async {
  final bloc = context.read<AuthBloc>();
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final code in const ['vi', 'en'])
            ListTile(
              title: Text(_languageLabel(code)),
              trailing: code == current ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                if (code != current) {
                  bloc.add(AuthEvent.preferredLanguageChanged(code));
                }
                Navigator.of(sheetContext).pop();
              },
            ),
        ],
      ),
    ),
  );
}
