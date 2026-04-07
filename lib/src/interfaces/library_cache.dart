import 'library.dart';

abstract interface class LibraryCache {

  Future<Library> getById(String id);

  List<Library> getAll();

  Future<void> update();
}