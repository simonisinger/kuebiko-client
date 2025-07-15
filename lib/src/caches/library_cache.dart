import 'package:kuebiko_client/src/interfaces/library_cache.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';
import 'package:kuebiko_client/src/models/library.dart';

import '../interfaces/cache_controller.dart';
import '../interfaces/library.dart';

class KuebikoLibraryCache implements LibraryCache {

  List<Library> _elements = [];
  bool init = true;
  final KuebikoHttpClient _httpClient;
  final CacheController _cacheController;

  KuebikoLibraryCache(this._cacheController, this._httpClient);

  Future<Library> getById(int id) async {
    try {
      return _elements.firstWhere((element) => element.id == id);
    } catch (e){
      await update();
      return _elements.firstWhere((element) => element.id == id);
    }
  }

  List<Library> getAll() => _elements;

  Future<void> update() async {
    List<Library> libraries = await KuebikoLibrary.getAll(_cacheController, this._httpClient);
    libraries.forEach((Library library) {
      try {
        _elements.firstWhere((Library element) => element.id == library.id);
      }catch(exception){
        this._elements.add(library);
      }
    });
    init = false;
  }
}