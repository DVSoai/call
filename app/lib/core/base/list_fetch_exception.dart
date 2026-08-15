/// Exception gọn cho [ListBlocMixin.fetchData] — toString() trả thẳng
/// message (không có tiền tố "Exception:"/"Bad state:") để hiện lên UI
/// (buildErrorState) sạch sẽ.
class ListFetchException implements Exception {
  final String message;

  const ListFetchException(this.message);

  @override
  String toString() => message;
}
