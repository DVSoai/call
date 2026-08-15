import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../base/failure.dart';

/// Mọi usecase implement contract này — 1 usecase = 1 hành động nghiệp vụ
/// duy nhất (vd. DevLoginUseCase, GetCallHistoryUseCase).
abstract class UseCase<R, Params> {
  Future<Either<Failure, R>> call(Params params);
}

/// Dùng cho usecase không cần tham số đầu vào.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Tham số phân trang dùng chung cho các usecase trả về danh sách.
class PageParams extends Equatable {
  final int page;
  final int limit;

  const PageParams({required this.page, required this.limit});

  @override
  List<Object?> get props => [page, limit];
}
