import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../kuebiko_multipart_request.dart';
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
    http.MultipartRequest req = KuebikoMultipartRequest(
        'POST',
        httpClient,
        httpClient.config.generateApiUri('/upload')
    );

    fileStream = fileStream.asBroadcastStream();
    req.files.add(
        http.MultipartFile('book', fileStream, fileLength, filename: filename)
    );
    req.fields['library'] = library.id.toString();
    req.fields['name'] = meta.name;
    req.fields['language'] = meta.language;
    req.fields['author'] = meta.author;
    req.fields['release_date'] = meta.releaseDate.toString();
    req.fields['number'] = meta.volNumber.toString();
    req.fields['max_page'] = meta.maxPage.toString();

    Future<Book> book = req.send()
        .then((http.StreamedResponse stream) => stream.stream.toList())
        .then((List<List<int>> responseRaw) {
          List<int> responseMergedRaw = [];
          responseRaw.forEach((List<int> list) => responseMergedRaw.addAll(list));
          String responseContent = utf8.decode(responseMergedRaw);
          Map jsonContent = jsonDecode(responseContent);
          return KuebikoBook(
              jsonContent['bookId'],
              library,
              jsonContent['bookName'],
              cacheController,
              httpClient
          );
        });

    return KuebikoUpload(_getPercentageStream(fileStream, fileLength), book);
  }

  static Stream<double> _getPercentageStream(Stream<List<int>> fileStream, int length) async* {
    int progress = 0;
    double onePercent = length / 100;
    await for (List<int> chunk in fileStream) {
      progress += chunk.length;
      yield progress / onePercent;
    }
  }

  static getBooks(BookSorting sort, SortingDirection direction, CacheController cacheController, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri(
        '/books',
        queryParameters: {
          'sort': sort.toString(),
          'direction': direction.toString()
        }
    );
    http.Response res = await httpClient.get(uri);
    Map json = jsonDecode(res.body);
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
    http.Response res = await _httpClient.put(uri);
    return jsonDecode(res.body)['convertId'];
  }

  Future<String> convertStatus(String convertId) async {
    Uri uri = _httpClient.config.generateApiUri(
        '/convert/status',
        queryParameters: {
          'convertId': convertId
        }
    );
    http.Response res = await _httpClient.get(uri);
    return jsonDecode(res.body)['status'];
  }

  void delete() async {
    Uri uri = _httpClient.config.generateApiUri(
        '/delete',
        queryParameters: {
          'library': _library.id.toString(),
          'book': this.id.toString()
        }
    );
    _httpClient.delete(uri);
  }

  Future<Map> metadata() async{
    Uri uri = _httpClient.config.generateApiUri(
        '/metadata',
        queryParameters: {
          'library': _library.id.toString(),
          'book': id.toString()
        }
    );
    http.Response res = await _httpClient.get(uri);
    Map metadata = jsonDecode(res.body)['book'];
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

    http.Response res = await _httpClient.get(uri);
    return res.bodyBytes;
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
    http.Response res = await _httpClient.get(uri);
    Map json = jsonDecode(res.body);
    if(json['reading_page'] is double){
      json['reading_page'] = json['reading_page'].toInt();
    }
    return Progress(currentPage: json['reading_page'], maxPage: json['max_page']);
  }
}