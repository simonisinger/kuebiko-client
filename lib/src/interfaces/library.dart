import 'package:kuebiko_client/src/models/upload.dart';

import '../interfaces/book.dart';
import '../models/book_meta.dart';
import '../models/series.dart';

abstract interface class Library {
  final int id;
  String name;
  String path;

  Library(this.id, this.name, this.path);

  void scan();

  void update();

  void renewMetadata();

  Future<void> delete();
  Future<List<Series>> series();

  KuebikoUpload upload(String filename, BookMeta meta, Stream<List<int>> fileContent, int fileLength);

  Future<List<Book>> books(BookSorting sorting, SortingDirection direction);
}