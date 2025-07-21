import 'dart:async';
import 'dart:convert';

import 'package:image/image.dart';
import 'package:kuebiko_client/src/kuebiko_multipart_request.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:kuebiko_client/src/models/download.dart';
import 'package:kuebiko_client/src/models/progress.dart';

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


  static Future<KuebikoBook> upload(Library library, BookMeta meta, CacheController cacheController, KuebikoHttpClient httpClient, String filename, Stream<List<int>> fileStream, int fileLength) async {
    http.MultipartRequest req = KuebikoMultipartRequest(
        'POST',
        httpClient,
        httpClient.config.generateApiUri('/upload')
    );


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

    http.StreamedResponse res = await req.send();
    List<int> responseMergedRaw = [];
    List<List<int>> responseRaw = await res.stream.toList();
    responseRaw.forEach((List<int> list) => responseMergedRaw.addAll(list));
    String responseContent = utf8.decode(responseMergedRaw);
    print(responseContent);
    Map jsonContent = jsonDecode(responseContent);
    KuebikoBook book = KuebikoBook(jsonContent['bookId'], library, jsonContent['bookName'], cacheController, httpClient);
    return book;
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

    for(int i = 0; i < bookRaw.length; i++){
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

  Future<Image?> cover() async{
    Uri uri = this._httpClient.config.generateApiUri(
        '/cover',
        queryParameters: {
          'library': _library.id.toString(),
          'book': this.id.toString()
        }
    );

    http.Response res = await _httpClient.get(uri);
    return decodeImage(res.bodyBytes);
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