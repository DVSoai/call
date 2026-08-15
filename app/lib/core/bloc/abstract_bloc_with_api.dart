import 'package:flutter_bloc/flutter_bloc.dart';

import '../usecases/usecase.dart';
import '../utils/app_logger.dart';

/// Base Bloc cho mọi Bloc gọi API qua [UseCase] — chuẩn hoá try/call/fold
/// (`Either<Failure, T>`) thành 2 callback onSuccess/onFailure, tránh lặp
/// lại boilerplate try/catch + fold ở từng Bloc.
abstract class BlocWithApi<E, S> extends Bloc<E, S> {
  BlocWithApi(super.initialState);

  // Cache trong RAM theo vòng đời app — đủ dùng cho dữ liệu ít thay đổi
  // (vd. TURN credentials). Không cần bền vững qua restart app.
  static final Map<String, dynamic> _cache = {};

  Future<void> callApi<T, P>({
    required UseCase<T, P> useCase,
    P? param,
    required Future<void> Function(T data) onSuccess,
    required void Function(String errorMessage) onFailure,
    bool useCache = false,
  }) async {
    if (param == null && P != NoParams) {
      AppLogger.e('callApi: thiếu params bắt buộc cho $P');
      if (!isClosed) onFailure('Thiếu tham số bắt buộc');
      return;
    }

    final checkedParam = param ?? const NoParams() as P;
    final cacheKey = '$T-${checkedParam.hashCode}';

    if (useCache) {
      final cached = _cache[cacheKey] as T?;
      if (cached != null) {
        if (isClosed) return;
        await onSuccess(cached);
        return;
      }
    }

    try {
      final result = await useCase.call(checkedParam);
      if (isClosed) return;
      await result.fold(
        (failure) {
          AppLogger.e(failure.message);
          onFailure(failure.message);
        },
        (data) async {
          if (useCache) _cache[cacheKey] = data;
          await onSuccess(data);
        },
      );
    } catch (e, st) {
      AppLogger.e('callApi lỗi ngoài dự kiến', e, st);
      if (!isClosed) onFailure(e.toString());
    }
  }

  static void clearCache() => _cache.clear();

  static void clearCacheByPattern(String pattern) {
    _cache.removeWhere((key, _) => key.contains(pattern));
  }
}
