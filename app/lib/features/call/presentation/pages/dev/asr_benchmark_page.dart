import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Màn hình đo baseline độ trễ ASR — bước bắt buộc trước khi ghép Whisper
/// vào luồng gọi thật (docs/CALL_SYSTEM.md §8.6c). CHỈ là công cụ đo nhanh
/// cho dev, KHÔNG phải màn hình sản phẩm: không có trong app_router, không
/// dùng CallBloc, vào qua nút riêng ở ProfilePage (xoá khi đo xong).
///
/// Model KHÔNG bundle trong repo/app assets (đúng nguyên tắc §8.3 — tải về
/// khi cần, cache local). Ở bước đo thử này, đẩy tạm 3 file model qua lệnh:
/// ```
/// adb push tiny-encoder.int8.onnx tiny-decoder.int8.onnx tiny-tokens.txt \
///   /sdcard/Android/data/APPLICATION_ID/files/whisper_test/
/// ```
/// rồi bấm "Tải model" trong màn hình này.
class AsrBenchmarkPage extends StatefulWidget {
  const AsrBenchmarkPage({super.key});

  @override
  State<AsrBenchmarkPage> createState() => _AsrBenchmarkPageState();
}

class _AsrBenchmarkPageState extends State<AsrBenchmarkPage> {
  static const _recordSeconds = 5;

  final _recorder = AudioRecorder();
  sherpa.OfflineRecognizer? _recognizer;
  bool _isRecording = false;
  bool _isBusy = false;
  String _status = 'Chưa tải model';
  String _transcript = '';
  int? _lastElapsedMs;

  @override
  void dispose() {
    _recorder.dispose();
    _recognizer?.free();
    super.dispose();
  }

  Future<String> _modelDir() async {
    final dir = await getExternalStorageDirectory();
    return '${dir!.path}/whisper_test';
  }

  Future<void> _loadModel() async {
    setState(() {
      _isBusy = true;
      _status = 'Đang tải model...';
    });
    final dir = await _modelDir();
    try {
      sherpa.initBindings();
      final config = sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: '$dir/tiny-encoder.int8.onnx',
            decoder: '$dir/tiny-decoder.int8.onnx',
            // Ép cứng tiếng Việt thay vì để Whisper tự đoán ngôn ngữ — với
            // đoạn audio ngắn (5s), model tiny tự đoán rất hay sai (từng ra
            // hẳn chữ Hán khi test thật), đoán sai ngôn ngữ thì dịch sai
            // ngay từ bước đầu, không liên quan gì tới bước MT sau này.
            language: 'vi',
          ),
          tokens: '$dir/tiny-tokens.txt',
          modelType: 'whisper',
          numThreads: 2,
          debug: false,
        ),
      );
      _recognizer = sherpa.OfflineRecognizer(config);
      setState(() {
        _status = 'Model sẵn sàng — bấm "Ghi $_recordSeconds giây" rồi nói vài câu';
      });
    } catch (e) {
      setState(() => _status = 'Lỗi tải model (đã đẩy đủ 3 file vào $dir chưa?): $e');
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Future<void> _recordAndTranscribe() async {
    if (_recognizer == null) return;
    if (!await _recorder.hasPermission()) {
      setState(() => _status = 'Chưa được cấp quyền micro');
      return;
    }

    final tmpDir = await getTemporaryDirectory();
    final path = '${tmpDir.path}/asr_benchmark.wav';
    setState(() {
      _isRecording = true;
      _isBusy = true;
      _transcript = '';
      _status = 'Đang ghi $_recordSeconds giây — nói vài câu...';
    });

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path,
    );
    await Future<void>.delayed(const Duration(seconds: _recordSeconds));
    await _recorder.stop();

    setState(() {
      _isRecording = false;
      _status = 'Đang nhận dạng...';
    });

    final stopwatch = Stopwatch()..start();
    final wave = sherpa.readWave(path);
    final stream = _recognizer!.createStream();
    stream.acceptWaveform(samples: wave.samples, sampleRate: wave.sampleRate);
    _recognizer!.decode(stream);
    final result = _recognizer!.getResult(stream);
    stream.free();
    stopwatch.stop();

    setState(() {
      _transcript = result.text;
      _lastElapsedMs = stopwatch.elapsedMilliseconds;
      _status = 'Xong — nhận dạng ${_recordSeconds}s audio mất ${stopwatch.elapsedMilliseconds}ms';
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final modelReady = _recognizer != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Đo thử ASR (dev)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status),
            const SizedBox(height: 16),
            if (!modelReady)
              ElevatedButton(
                onPressed: _isBusy ? null : _loadModel,
                child: const Text('Tải model'),
              ),
            if (modelReady)
              ElevatedButton(
                onPressed: _isRecording || _isBusy ? null : _recordAndTranscribe,
                child: Text(_isRecording ? 'Đang ghi...' : 'Ghi $_recordSeconds giây & nhận dạng'),
              ),
            const SizedBox(height: 24),
            if (_lastElapsedMs != null)
              Text(
                'Thời gian xử lý: $_lastElapsedMs ms',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            const SizedBox(height: 8),
            Text('Kết quả: $_transcript'),
          ],
        ),
      ),
    );
  }
}
