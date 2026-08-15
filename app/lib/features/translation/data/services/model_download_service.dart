import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/utils/app_logger.dart';
import 'translation_pipeline_config.dart';

/// Toàn bộ file model cần cho 1 hướng dịch cụ thể (vd. vi→en) — trả về bởi
/// [ModelDownloadService.ensurePipelineConfig], đủ để dựng thẳng
/// [TranslationPipelineConfig] mà không cần biết gì thêm về URL/cache.
typedef _MtDirection = ({
  String encoderUrl,
  String decoderUrl,
  String tokenizerUrl,
  int decoderStartTokenId,
  int eosTokenId,
});

/// Tải + cache model cho Translated Call (docs/CALL_SYSTEM.md §8.3) — CHỈ
/// tải khi user bật tính năng lần đầu, KHÔNG bundle sẵn trong repo/app
/// assets. Bỏ qua tải lại nếu file đã có sẵn (check theo tên file, không
/// cần checksum cho v1 — đủ dùng, tránh over-engineer).
///
/// v1 chỉ hỗ trợ Việt ⇄ Anh (xem kế hoạch) — 2 hướng dịch hardcode ở đây,
/// thêm ngôn ngữ sau chỉ cần thêm 1 entry vào [_mtDirections], không đổi gì
/// khác trong pipeline.
class ModelDownloadService {
  // Dio riêng, KHÔNG dùng chung instance của DioClient (core/network) — cái
  // đó gắn baseUrl + interceptor auth cho API của chính app, không phù hợp
  // để tải file tĩnh từ HuggingFace/GitHub (khác host, không cần auth).
  final Dio _dio = Dio();

  static const _whisperEncoderUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main/tiny-encoder.int8.onnx';
  static const _whisperDecoderUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main/tiny-decoder.int8.onnx';
  static const _whisperTokensUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main/tiny-tokens.txt';
  static const _vadUrl = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx';

  // Token id lấy từ generation_config.json của từng model (Marian mỗi cặp
  // ngôn ngữ có vocab/id riêng, không dùng chung được).
  static const _mtDirections = <String, _MtDirection>{
    'vi-en': (
      encoderUrl: 'https://huggingface.co/Xenova/opus-mt-vi-en/resolve/main/onnx/encoder_model_quantized.onnx',
      decoderUrl: 'https://huggingface.co/Xenova/opus-mt-vi-en/resolve/main/onnx/decoder_model_quantized.onnx',
      tokenizerUrl: 'https://huggingface.co/Xenova/opus-mt-vi-en/resolve/main/tokenizer.json',
      decoderStartTokenId: 53738,
      eosTokenId: 0,
    ),
    'en-vi': (
      encoderUrl: 'https://huggingface.co/Xenova/opus-mt-en-vi/resolve/main/onnx/encoder_model_quantized.onnx',
      decoderUrl: 'https://huggingface.co/Xenova/opus-mt-en-vi/resolve/main/onnx/decoder_model_quantized.onnx',
      tokenizerUrl: 'https://huggingface.co/Xenova/opus-mt-en-vi/resolve/main/tokenizer.json',
      decoderStartTokenId: 53684,
      eosTokenId: 0,
    ),
  };

  Future<String> _modelsDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/translated_call_models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Tải (nếu chưa có) + trả về đường dẫn cục bộ. An toàn gọi nhiều lần —
  /// file đã tồn tại thì bỏ qua ngay, không tải lại.
  Future<String> _ensureFile(
    String url,
    String filename, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _modelsDir();
    final path = '$dir/$filename';
    final file = File(path);
    if (await file.exists()) return path;

    // Tải ra file tạm rồi rename — nếu app bị kill/mất mạng giữa chừng,
    // không để lại file .onnx dở dang bị tưởng nhầm là "đã tải xong".
    final tmpPath = '$path.part';
    try {
      await _dio.download(
        url,
        tmpPath,
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      await File(tmpPath).rename(path);
    } catch (e, st) {
      AppLogger.e('ModelDownloadService: tải $filename lỗi', e, st);
      await File(tmpPath).delete().catchError((_) => File(tmpPath));
      rethrow;
    }
    return path;
  }

  /// [sourceLanguage]/[targetLanguage] chỉ nhận 'vi'/'en' ở v1 — ném lỗi rõ
  /// ràng nếu gọi với ngôn ngữ khác thay vì âm thầm dùng sai model.
  Future<TranslationPipelineConfig> ensurePipelineConfig({
    required String sourceLanguage,
    required String targetLanguage,
    void Function(double progress)? onProgress,
  }) async {
    final directionKey = '$sourceLanguage-$targetLanguage';
    final direction = _mtDirections[directionKey];
    if (direction == null) {
      throw ArgumentError('ModelDownloadService: chưa hỗ trợ hướng dịch $directionKey (v1 chỉ có vi-en/en-vi)');
    }

    // 7 file tổng cộng (3 whisper + 1 vad dùng chung mọi hướng, 3 mt riêng
    // hướng này) — tính progress gộp đơn giản bằng trung bình cộng, đủ dùng
    // cho UI "đang tải model..." không cần chính xác tuyệt đối.
    var completedWeight = 0.0;
    const totalFiles = 7;
    void reportStep(double fileProgress) {
      onProgress?.call((completedWeight + fileProgress) / totalFiles);
    }

    final whisperEncoder = await _ensureFile(_whisperEncoderUrl, 'whisper-tiny-encoder.int8.onnx', onProgress: reportStep);
    completedWeight += 1;
    final whisperDecoder = await _ensureFile(_whisperDecoderUrl, 'whisper-tiny-decoder.int8.onnx', onProgress: reportStep);
    completedWeight += 1;
    final whisperTokens = await _ensureFile(_whisperTokensUrl, 'whisper-tiny-tokens.txt', onProgress: reportStep);
    completedWeight += 1;
    final vadModel = await _ensureFile(_vadUrl, 'silero-vad.onnx', onProgress: reportStep);
    completedWeight += 1;
    final mtEncoder = await _ensureFile(direction.encoderUrl, 'mt-$directionKey-encoder.onnx', onProgress: reportStep);
    completedWeight += 1;
    final mtDecoder = await _ensureFile(direction.decoderUrl, 'mt-$directionKey-decoder.onnx', onProgress: reportStep);
    completedWeight += 1;
    final mtTokenizer = await _ensureFile(direction.tokenizerUrl, 'mt-$directionKey-tokenizer.json', onProgress: reportStep);

    return TranslationPipelineConfig(
      vadModelPath: vadModel,
      whisperEncoderPath: whisperEncoder,
      whisperDecoderPath: whisperDecoder,
      whisperTokensPath: whisperTokens,
      sourceLanguage: sourceLanguage,
      mtEncoderPath: mtEncoder,
      mtDecoderPath: mtDecoder,
      mtTokenizerJsonPath: mtTokenizer,
      mtDecoderStartTokenId: direction.decoderStartTokenId,
      mtEosTokenId: direction.eosTokenId,
    );
  }
}
