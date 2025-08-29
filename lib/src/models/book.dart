import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../kuebiko_http_client.dart';
import '../models/download.dart';
import '../models/progress.dart';
import '../models/upload.dart';
import '../interfaces/book.dart';
import '../interfaces/cache_controller.dart';
import '../interfaces/library.dart';
import 'book_meta.dart';

class KuebikoBook implements Book {
  final int id;
  String name;
  Library _library;
  final CacheController _cacheController;

  final KuebikoHttpClient _httpClient;

  KuebikoBook(this.id, this._library, this.name, this._cacheController, this._httpClient);


  static KuebikoUpload upload(Library library, BookMeta meta, CacheController cacheController, KuebikoHttpClient httpClient, String filename, Stream<List<int>> fileStream, int fileLength) {
    final progressController = StreamController<double>();

    final formData = FormData.fromMap({
      'book': MultipartFile.fromStream(
        () => fileStream,
        fileLength,
        filename: filename,
      ),
      'library': library.id.toString(),
      'name': meta.name,
      'language': meta.language,
      'author': meta.author,
      'release_date': meta.releaseDate.toString(),
      'number': meta.volNumber.toString(),
      'max_page': meta.maxPage.toString(),
    });

    Future<Book> book = httpClient.uploadWithProgress(
      httpClient.config.generateApiUri('/upload').toString(),
      formData,
      onSendProgress: (sent, total) {
        if (total > 0) {
          final percentage = (sent / total) * 100;
          progressController.add(percentage);
        }
      },
    ).then((Response response) {
      progressController.close();
      Map jsonContent = response.data is Map 
          ? response.data 
          : jsonDecode(response.data.toString());
      return KuebikoBook(
          jsonContent['bookId'],
          library,
          jsonContent['bookName'],
          cacheController,
          httpClient
      );
    }).catchError((error) {
      progressController.close();
      throw error;
    });

    return KuebikoUpload(progressController.stream, book);
  }

  static getBooks(BookSorting sort, SortingDirection direction, CacheController cacheController, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri(
        '/books',
        queryParameters: {
          'sort': sort.toString(),
          'direction': direction.toString()
        }
    );
    Response res = await httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    List bookRaw = json['books'];

    List<Book> books = [];

    for (int i = 0; i < bookRaw.length; i++) {
      Map book = bookRaw[i];
      Library library = await cacheController.libraryCache.getById(book['library']);
      books.add(KuebikoBook(book['id'], library, book['name'], cacheController, httpClient));
    }

    return books;
  }

  Future<KuebikoDownload> download(Formats format) async {
    Uri uri = this._httpClient.config.generateApiUri(
        '/download',
        queryParameters: {
          'library': this._library.id.toString(),
          'book': this.id.toString(),
          'format': format.name
        }
    );
    return await this._httpClient.getFile(uri);
  }

  Future<String> convert(Formats format) async {
    Uri uri = this._httpClient.config.generateApiUri(
        '/convert',
        queryParameters: {
          'library': _library.id.toString(),
          'book': this.id.toString(),
          'format': format.toString()
        }
    );
    Response res = await _httpClient.put(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    return json['convertId'];
  }

  Future<String> convertStatus(String convertId) async {
    Uri uri = _httpClient.config.generateApiUri(
        '/convert/status',
        queryParameters: {
          'convertId': convertId
        }
    );
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    return json['status'];
  }

  Future<void> delete() async {
    Uri uri = _httpClient.config.generateApiUri(
        '/delete',
        queryParameters: {
          'library': _library.id.toString(),
          'book': this.id.toString()
        }
    );
    await _httpClient.delete(uri);
  }

  Future<Map> metadata() async{
    Uri uri = _httpClient.config.generateApiUri(
        '/metadata',
        queryParameters: {
          'library': _library.id.toString(),
          'book': id.toString()
        }
    );
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    Map metadata = json['book'];
    if (metadata['series'] != null) {
      metadata['series'] = await _cacheController.seriesCache.getById(metadata['series']['id']);
    }
    return metadata;
  }

  void renewMetadata() {
    Uri uri = _httpClient.config.generateApiUri(
        '/book/metadata',
        queryParameters: {
          'library': _library.id.toString(),
          'book': id.toString()
        }
    );

    _httpClient.put(uri);
  }

  Future<Uint8List> cover() async {
    Uri uri = this._httpClient.config.generateApiUri(
        '/cover',
        queryParameters: {
          'library': _library.id.toString(),
          'book': this.id.toString()
        }
    );

    Response res = await _httpClient.get(uri);
    if (res.data is Uint8List) {
      return res.data;
    } else if (res.data is List<int>) {
      return Uint8List.fromList(res.data.cast<int>());
    } else {
      return Uint8List.fromList(res.data.toString().codeUnits);
    }
  }

  Future<void> setProgress(Progress progress) async {
    Uri uri = this._httpClient.config.generateApiUri(
        '/' + _library.id.toString() + '/' + this.id.toString() + '/progress',
      queryParameters: {
          'reading_page': progress.currentPage.toString()
      }
    );
    await _httpClient.put(uri);
  }

  Future<Progress> getProgress() async {
    Uri uri = this._httpClient.config.generateApiUri(
        '/' + _library.id.toString() + '/' + this.id.toString() + '/progress'
    );
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    if(json['reading_page'] is double){
      json['reading_page'] = json['reading_page'].toInt();
    }
    return Progress(currentPage: json['reading_page'], maxPage: json['max_page']);
  }
}