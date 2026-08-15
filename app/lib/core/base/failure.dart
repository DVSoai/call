/// Lỗi domain chuẩn hoá — mọi repository trả về [Failure] qua [Either]
/// (fpdart) thay vì throw exception thẳng ra presentation layer.
class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => 'Failure($message)';
}
