import '../interfaces/book.dart';

class KuebikoUpload {
  Stream<double> stream;
  Future<Book> book;

  KuebikoUpload(this.stream, this.book);
}