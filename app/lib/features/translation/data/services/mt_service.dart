import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

import '../../../../core/utils/app_logger.dart';

/// Dịch máy on-device bằng model MarianMT/OPUS-MT dạng ONNX (encoder +
/// decoder tách riêng, không dùng past_key_values — xem
/// docs/CALL_SYSTEM.md §8, kế hoạch Translated Call). 1 instance = 1 hướng
/// dịch (vd. vi→en) — cần 2 instance nếu muốn dịch cả 2 chiều.
///
/// Chủ động dò tên input/output tensor qua [OrtSession.inputNames]/
/// [outputNames] thay vì hardcode chuỗi cố định — export ONNX từ Optimum
/// cho model seq2seq không hoàn toàn thống nhất tên giữa các nguồn (đã khảo
/// sát, thấy ít nhất 2 kiểu đặt tên khác nhau ngoài thực tế), dò theo
/// substring an toàn hơn đoán sai 1 cái tên rồi lỗi khó hiểu lúc chạy.
class MtService {
  final _runtime = OnnxRuntime();
  OrtSession? _encoderSession;
  OrtSession? _decoderSession;
  SentencePieceTokenizer? _tokenizer;
  int _decoderStartTokenId = 0;
  int _eosTokenId = 0;

  /// Giới hạn tối đa số token sinh ra — câu trong hội thoại gọi điện thường
  /// ngắn, không cần cho phép sinh dài như dịch văn bản/tài liệu.
  static const _maxNewTokens = 64;

  bool get isLoaded => _encoderSession != null && _decoderSession != null && _tokenizer != null;

  Future<void> load({
    required String encoderPath,
    required String decoderPath,
    required String tokenizerJsonPath,
    required int decoderStartTokenId,
    required int eosTokenId,
  }) async {
    _tokenizer = HuggingFaceTokenizerLoader.fromJsonFileSync(tokenizerJsonPath);
    _encoderSession = await _runtime.createSession(encoderPath);
    _decoderSession = await _runtime.createSession(decoderPath);
    _decoderStartTokenId = decoderStartTokenId;
    _eosTokenId = eosTokenId;
    AppLogger.i(
      'MtService: đã tải model — encoder inputs=${_encoderSession!.inputNames} '
      'decoder inputs=${_decoderSession!.inputNames} outputs=${_decoderSession!.outputNames}',
    );
  }

  Future<void> dispose() async {
    await _encoderSession?.close();
    await _decoderSession?.close();
    _encoderSession = null;
    _decoderSession = null;
    _tokenizer = null;
  }

  /// Dịch 1 câu nguồn — greedy decode (không beam search), phù hợp câu ngắn
  /// trong hội thoại, đơn giản hoá chấp nhận được cho v1.
  Future<String> translate(String sourceText) async {
    final tokenizer = _tokenizer;
    final encoder = _encoderSession;
    final decoder = _decoderSession;
    if (tokenizer == null || encoder == null || decoder == null) {
      throw StateError('MtService: chưa gọi load()');
    }

    final encoding = tokenizer.encode(sourceText);
    final srcIds = Int64List.fromList(encoding.ids);
    final srcMask = Int64List.fromList(List.filled(srcIds.length, 1));

    final disposables = <OrtValue>[];
    try {
      final srcIdsTensor = await OrtValue.fromList(srcIds, [1, srcIds.length]);
      final srcMaskTensor = await OrtValue.fromList(srcMask, [1, srcIds.length]);
      disposables.addAll([srcIdsTensor, srcMaskTensor]);

      final encoderOutputs = await encoder.run({
        _matchInputName(encoder.inputNames, const ['input_ids']): srcIdsTensor,
        _matchInputName(encoder.inputNames, const ['attention_mask']): srcMaskTensor,
      });
      final encoderHidden = encoderOutputs[encoder.outputNames.first]!;
      disposables.add(encoderHidden);

      final decoderTokens = <int>[_decoderStartTokenId];
      for (var step = 0; step < _maxNewTokens; step++) {
        final stepIdsTensor = await OrtValue.fromList(
          Int64List.fromList(decoderTokens),
          [1, decoderTokens.length],
        );

        final inputs = <String, OrtValue>{};
        for (final name in decoder.inputNames) {
          final lower = name.toLowerCase();
          if (lower.contains('encoder_hidden') || lower.contains('encoder_outputs')) {
            inputs[name] = encoderHidden;
          } else if (lower.contains('encoder') && lower.contains('attention')) {
            inputs[name] = srcMaskTensor;
          } else if (lower.contains('input_ids')) {
            inputs[name] = stepIdsTensor;
          } else if (lower.contains('attention_mask')) {
            // Chỉ có đúng 1 attention_mask (không có tiền tố "encoder_") —
            // theo cấu trúc decoder-không-past chuẩn, đây vẫn là mask của
            // ENCODER (self-attention của decoder dùng causal mask dựng sẵn
            // trong graph, không nhận từ ngoài) — đã xác nhận qua khảo sát.
            inputs[name] = srcMaskTensor;
          }
        }

        final decoderOutputs = await decoder.run(inputs);
        await stepIdsTensor.dispose();

        final logitsValue = decoderOutputs[decoder.outputNames.first]!;
        final nextToken = await _argmaxLastStep(logitsValue, decoderTokens.length);
        await logitsValue.dispose();

        if (nextToken == _eosTokenId) break;
        decoderTokens.add(nextToken);
      }

      // Bỏ token decoder_start ở đầu — không thuộc câu dịch.
      final outputIds = decoderTokens.skip(1).toList();
      return tokenizer.decode(outputIds).trim();
    } finally {
      for (final v in disposables) {
        await v.dispose();
      }
    }
  }

  /// Logits có shape [1, seqLen, vocabSize] — chỉ cần vị trí cuối (token vừa
  /// sinh dự đoán token TIẾP THEO, không dùng past_key_values nên phải chạy
  /// lại toàn bộ chuỗi mỗi bước, xem docstring class).
  Future<int> _argmaxLastStep(OrtValue logits, int seqLen) async {
    final flat = await logits.asFlattenedList();
    final vocabSize = flat.length ~/ seqLen;
    final offset = (seqLen - 1) * vocabSize;
    var bestIdx = 0;
    var bestScore = double.negativeInfinity;
    for (var i = 0; i < vocabSize; i++) {
      final score = (flat[offset + i] as num).toDouble();
      if (score > bestScore) {
        bestScore = score;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  String _matchInputName(List<String> names, List<String> candidates) {
    for (final candidate in candidates) {
      for (final name in names) {
        if (name.toLowerCase() == candidate) return name;
      }
    }
    for (final candidate in candidates) {
      for (final name in names) {
        if (name.toLowerCase().contains(candidate)) return name;
      }
    }
    throw StateError('MtService: không tìm thấy input tensor khớp $candidates trong $names');
  }
}
