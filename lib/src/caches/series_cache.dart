import 'package:kuebiko_client/src/kuebiko_http_client.dart';

import '../interfaces/cache_controller.dart';
import '../interfaces/series.dart';
import '../models/series.dart';

class SeriesCache {

  List<Series> _elements = [];
  bool init = true;
  final CacheController _cacheController;
  final KuebikoHttpClient _httpClient;

  SeriesCache(this._cacheController, this._httpClient);

  Future<Series> getById(int id) async {
    try {
      return _elements.firstWhere((element) => element.id == id);
    }catch (e){
      await update();
      return _elements.firstWhere((element) => element.id == id);
    }
  }

  List<Series> getAll() => _elements;

  Future<void> update() async {
    List<Series> libraries = await KuebikoSeries.getAll(_cacheController, _httpClient);
    libraries.forEach((Series library) {
      try {
        _elements.firstWhere((Series element) => element.id == library.id);
      }catch(exception){
        this._elements.add(library);
      }
    });
    init = false;
  }
}