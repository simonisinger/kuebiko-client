
import 'package:kuebiko_client/src/caches/library_cache.dart';
import 'package:kuebiko_client/src/caches/series_cache.dart';
import 'package:kuebiko_client/src/interfaces/cache_controller.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';

import '../interfaces/library_cache.dart';

class KuebikoCacheController implements CacheController {
  late final LibraryCache _libraryCache;
  late final SeriesCache _seriesCache;
  final KuebikoHttpClient _httpClient;

  KuebikoCacheController(this._httpClient){
    this._libraryCache = KuebikoLibraryCache(this, _httpClient);
    this._seriesCache = SeriesCache(this, _httpClient);
  }

  get libraryCache => _libraryCache;

  get seriesCache => _seriesCache;
}