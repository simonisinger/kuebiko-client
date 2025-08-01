import 'dart:convert';

import 'package:kuebiko_client/src/interfaces/library.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';

import 'package:http/http.dart' as http;
import 'package:kuebiko_client/src/models/book.dart';
import 'package:kuebiko_client/src/models/series.dart';
import 'package:kuebiko_client/src/models/upload.dart';

import '../interfaces/book.dart';
import '../interfaces/cache_controller.dart';
import 'book_meta.dart';

class KuebikoLibrary implements Library {
  final int id;
  String name;
  String path;
  final CacheController _cacheController;
  final KuebikoHttpClient _httpClient;

  KuebikoLibrary(this.id, this.name, this.path, this._cacheController, this._httpClient);

  static Future<List<Library>> getAll(CacheController cacheController, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri('/library');
    http.Response res = await httpClient.get(uri);
    Map json = jsonDecode(res.body);
    List rawLibrary = json['library'];
    return rawLibrary.map((library) => KuebikoLibrary(
        library['id'],
        library['name'],
        library['path'],
        cacheController,
        httpClient
    )).toList();
  }

  static Future<Library> create(String name, String path, CacheController cacheController, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri('/library/create');
    http.Response res = await httpClient.post(
        uri,
        body: {
          'path': path,
          'name': name
        }
    );
    Map json = jsonDecode(res.body);
    Library library = KuebikoLibrary(json['library'], name, path, cacheController, httpClient);
    await cacheController.libraryCache.update();
    return library;
  }

  KuebikoUpload upload(String filename, BookMeta meta, Stream<List<int>> fileContent, int fileLength)
  => KuebikoBook.upload(this, meta, _cacheController, _httpClient, filename, fileContent, fileLength);

  void scan() {
    Uri uri = _httpClient.config.generateApiUri(
        '/library/scan',
        queryParameters: {
          'library': id.toString()
        }
    );
    _httpClient.put(uri);
  }

  void update(){
    Uri uri = _httpClient.config.generateApiUri(
        '/library/update'
    );
    _httpClient.put(
        uri,
        body: {
          'library': id.toString(),
          'name': name,
          'path': path
        }
    );
  }

  void renewMetadata(){
    Uri uri = _httpClient.config.generateApiUri(
        '/library/metadata',
        queryParameters: {
          'library': id.toString()
        }
    );
    _httpClient.put(uri);
  }

  Future<void> delete() async {
    Uri uri = _httpClient.config.generateApiUri(
        '/library/delete',
        queryParameters: {
          'library': id.toString()
        }
    );
    await _httpClient.delete(uri);
  }

  Future<List<Series>> series() async {
    Uri uri = _httpClient.config.generateApiUri('/'+this.id.toString() + '/series');
    http.Response res = await _httpClient.get(uri);
    Map json = jsonDecode(res.body);
    List seriesRaw = json['series'];
    return seriesRaw.map((seriesSingle) => Series(
        seriesSingle['id'],
        seriesSingle['name'],
        seriesSingle['author'],
        seriesSingle['description'],
        seriesSingle['number_of_volumes'],
        seriesSingle['publisher'],
        seriesSingle['language'],
        seriesSingle['genre'],
        seriesSingle['age_rating'],
        seriesSingle['type'],
        seriesSingle['locked'].cast<String>(),
        _cacheController,
        _httpClient
    )).toList();
  }

  Future<List<Book>> books(BookSorting sorting, SortingDirection direction) async {
    Uri uri = _httpClient.config.generateApiUri(
        '/library/' + id.toString() + '/books',
        queryParameters: {
          'sort': sorting.name,
          'direction': direction.name
        }
    );

    http.Response res = await _httpClient.get(uri);
    Map json = jsonDecode(res.body);

    return json['books'].map<Book>((book) => KuebikoBook(
        book['id'],
        this,
        book['name'],
        _cacheController,
        _httpClient
    )).toList();
  }

  static Future<List<String>> getFolderContent(String path, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri(
        '/folder',
        queryParameters: {
          'path': path
        }
    );
    http.Response res = await httpClient.get(uri);
    return jsonDecode(res.body)['child'].cast<String>();
  }

  static Future<void> createFolder(String path, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri('/folder');
    await httpClient.put(uri);
  }

  static void scanAll(KuebikoHttpClient httpClient){
    Uri uri = httpClient.config.generateApiUri('/scan');
    httpClient.put(uri);
  }

  static void renewMetadataAll(KuebikoHttpClient httpClient){
    Uri uri = httpClient.config.generateApiUri('/renewMetadata');
    httpClient.put(uri);
  }
}