import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../../../core/utils/app_logger.dart';
import 'mt_service.dart';
import 'translation_pipeline_config.dart';

/// VAD → ASR → MT chạy trong 1 Dart Isolate RIÊNG cho toàn bộ vòng đời 1
/// cuộc gọi có bật phụ đề (docs/CALL_SYSTEM.md §8.6b) — BẮT BUỘC không chạy
/// trên main isolate: Whisper/MT tốn CPU thật (giây, không phải mili giây),
/// chạy chung thread với audio thật của flutter_webrtc sẽ làm cuộc gọi giật/
/// rớt tiếng ngay lập tức.
///
/// CallBloc sở hữu 1 instance/cuộc gọi (pattern giống hệt WebRtcService):
/// [start] load model 1 lần, [feedAudioSegment] đẩy từng file WAV (từ
/// WebRtcService.onRemoteAudioSegment) vào, kết quả dịch trả về qua
/// [onSubtitle]. [dispose] kill isolate khi tắt phụ đề/kết thúc cuộc gọi.
class TranslationPipeline {
  Isolate? _isolate;
  ReceivePort? _receivePort;
  SendPort? _commandPort;
  final _subtitleController = StreamController<String>.broadcast();

  Stream<String> get onSubtitle => _subtitleController.stream;

  Future<void> start(TranslationPipelineConfig config) async {
    final rootIsolateToken = RootIsolateToken.instance;
    if (rootIsolateToken == null) {
      throw StateError('TranslationPipeline: không lấy được RootIsolateToken');
    }

    final receivePort = ReceivePort();
    _receivePort = receivePort;
    final readyCompleter = Completer<SendPort>();

    receivePort.listen((message) {
      if (message is SendPort) {
        readyCompleter.complete(message);
      } else if (message is String) {
        if (!_subtitleController.isClosed) _subtitleController.add(message);
      } else if (message is _IsolateErrorReport) {
        AppLogger.w('TranslationPipeline: lỗi xử lý 1 đoạn audio trong isolate (bỏ qua, tiếp tục)', message.error);
      }
    });

    _isolate = await Isolate.spawn(
      _isolateEntryPoint,
      _IsolateStartMessage(
        sendPort: receivePort.sendPort,
        rootIsolateToken: rootIsolateToken,
        config: config,
      ),
    );
    _commandPort = await readyCompleter.future;
  }

  /// Đẩy 1 file WAV (đoạn audio người kia vừa ghi xong) vào pipeline — không
  /// chờ kết quả ở đây, bản dịch trả về bất đồng bộ qua [onSubtitle].
  void feedAudioSegment(String wavPath) {
    _commandPort?.send(wavPath);
  }

  Future<void> dispose() async {
    _commandPort?.send(const _ShutdownSignal());
    _commandPort = null;
    // Cho isolate 1 khoảng ngắn tự dọn model (free FFI/close ONNX session)
    // trước khi kill cứng — kill cứng vẫn là lưới an toàn cuối nếu isolate
    // treo, không được để dispose() của CallBloc bị chặn vô thời hạn.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _receivePort?.close();
    _receivePort = null;
    await _subtitleController.close();
  }
}

class _IsolateStartMessage {
  const _IsolateStartMessage({
    required this.sendPort,
    required this.rootIsolateToken,
    required this.config,
  });

  final SendPort sendPort;
  final RootIsolateToken rootIsolateToken;
  final TranslationPipelineConfig config;
}

class _ShutdownSignal {
  const _ShutdownSignal();
}

class _IsolateErrorReport {
  const _IsolateErrorReport(this.error);
  final String error;
}

/// Entry point của Isolate — BẮT BUỘC là hàm top-level (không phải closure/
/// method instance), yêu cầu của Isolate.spawn.
Future<void> _isolateEntryPoint(_IsolateStartMessage msg) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(msg.rootIsolateToken);
  // sherpa_onnx dùng FFI riêng theo từng isolate — bắt buộc init lại ở đây,
  // gọi initBindings() ở main isolate KHÔNG áp dụng cho isolate này.
  sherpa.initBindings();

  final commandPort = ReceivePort();
  msg.sendPort.send(commandPort.sendPort);

  final config = msg.config;

  final vad = sherpa.VoiceActivityDetector(
    config: sherpa.VadModelConfig(
      sileroVad: sherpa.SileroVadModelConfig(model: config.vadModelPath),
      sampleRate: 16000,
    ),
    bufferSizeInSeconds: 8,
  );

  final recognizer = sherpa.OfflineRecognizer(
    sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: config.whisperEncoderPath,
          decoder: config.whisperDecoderPath,
          language: config.sourceLanguage,
        ),
        tokens: config.whisperTokensPath,
        modelType: 'whisper',
        numThreads: 2,
        debug: false,
      ),
    ),
  );

  final mt = MtService();
  await mt.load(
    encoderPath: config.mtEncoderPath,
    decoderPath: config.mtDecoderPath,
    tokenizerJsonPath: config.mtTokenizerJsonPath,
    decoderStartTokenId: config.mtDecoderStartTokenId,
    eosTokenId: config.mtEosTokenId,
  );

  await for (final message in commandPort) {
    if (message is _ShutdownSignal) {
      break;
    }
    if (message is! String) continue;

    final wavPath = message;
    try {
      final translated = await _translateSegment(wavPath, vad, recognizer, mt);
      if (translated != null && translated.isNotEmpty) {
        msg.sendPort.send(translated);
      }
    } catch (e) {
      msg.sendPort.send(_IsolateErrorReport(e.toString()));
    } finally {
      _deleteQuietly(wavPath);
    }
  }

  vad.free();
  recognizer.free();
  await mt.dispose();
  commandPort.close();
}

/// VAD lọc khoảng lặng trong đoạn 4s → gộp phần có tiếng nói → ASR ra chữ →
/// MT dịch. Trả về null nếu đoạn này không có tiếng nói (im lặng/tạp âm).
Future<String?> _translateSegment(
  String wavPath,
  sherpa.VoiceActivityDetector vad,
  sherpa.OfflineRecognizer recognizer,
  MtService mt,
) async {
  final wave = sherpa.readWave(wavPath);
  if (wave.samples.isEmpty) return null;

  vad.acceptWaveform(wave.samples);
  vad.flush();

  final texts = <String>[];
  while (!vad.isEmpty()) {
    final segment = vad.front();
    vad.pop();
    // Đoạn quá ngắn (<0.3s ở 16kHz) — nhiễu/tiếng động, không đáng ASR.
    if (segment.samples.length < 16000 * 0.3) continue;

    final stream = recognizer.createStream();
    stream.acceptWaveform(samples: segment.samples, sampleRate: 16000);
    recognizer.decode(stream);
    final result = recognizer.getResult(stream);
    stream.free();

    final text = result.text.trim();
    if (text.isNotEmpty) texts.add(text);
  }
  vad.reset();

  if (texts.isEmpty) return null;
  return mt.translate(texts.join(' '));
}

void _deleteQuietly(String path) {
  File(path).delete().catchError((_) => File(path));
}
