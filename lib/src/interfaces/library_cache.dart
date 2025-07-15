import 'library.dart';

abstract interface class LibraryCache {

  Future<Library> getById(int id);

  List<Library> getAll();

  Future<void> update();
}