class BookMeta {
  final String name;
  final int volNumber;
  final DateTime releaseDate;
  final String author;
  final String language;
  final int maxPage;

  BookMeta({
    required this.name,
    required this.volNumber,
    required this.releaseDate,
    required this.author,
    required this.language,
    required this.maxPage
  });
}