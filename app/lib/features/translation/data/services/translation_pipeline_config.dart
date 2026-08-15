/// Toàn bộ đường dẫn file model + tham số cần để chạy VAD → ASR → MT trong
/// Isolate riêng (xem translation_pipeline.dart). Chỉ chứa dữ liệu (String/
/// int/double) — bắt buộc vì phải gửi qua SendPort sang Isolate khác, không
/// gửi được object có FFI pointer/platform channel bên trong.
///
/// Đường dẫn file do ModelDownloadService (bước tải/cache model) cung cấp —
/// class này không tự biết model tải từ đâu, chỉ biết đường dẫn cục bộ.
class TranslationPipelineConfig {
  const TranslationPipelineConfig({
    required this.vadModelPath,
    required this.whisperEncoderPath,
    required this.whisperDecoderPath,
    required this.whisperTokensPath,
    required this.sourceLanguage,
    required this.mtEncoderPath,
    required this.mtDecoderPath,
    required this.mtTokenizerJsonPath,
    required this.mtDecoderStartTokenId,
    required this.mtEosTokenId,
  });

  /// Ngôn ngữ NGƯỜI KIA đang nói — ép cứng vào Whisper thay vì auto-detect
  /// (xem Payload.PreferredLanguage phía backend + bug thật đã gặp lúc đo
  /// baseline: auto-detect đoán nhầm tiếng Việt sang tiếng Hán).
  final String sourceLanguage;

  final String vadModelPath;

  final String whisperEncoderPath;
  final String whisperDecoderPath;
  final String whisperTokensPath;

  /// Model MT ĐÚNG 1 CHIỀU (sourceLanguage → ngôn ngữ mình muốn nghe) — việc
  /// chọn đúng cặp encoder/decoder/tokenizer cho chiều nào là trách nhiệm
  /// của nơi tạo config này (CallBloc), không phải của pipeline.
  final String mtEncoderPath;
  final String mtDecoderPath;
  final String mtTokenizerJsonPath;
  final int mtDecoderStartTokenId;
  final int mtEosTokenId;
}
