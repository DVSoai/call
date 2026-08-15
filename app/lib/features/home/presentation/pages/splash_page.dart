import 'package:flutter/material.dart';

/// Hiện trong lúc AuthBloc kiểm tra token đã lưu (AuthEvent.sessionCheckRequested)
/// — router tự điều hướng sang /login hoặc /home ngay khi có kết quả.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
