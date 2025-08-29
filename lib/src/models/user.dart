import 'dart:convert';

import 'package:kuebiko_client/src/interfaces/user.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';
import 'package:dio/dio.dart';
import 'package:kuebiko_client/src/models/book.dart';

import '../interfaces/book.dart';
import '../interfaces/cache_controller.dart';

class KuebikoUser implements User {
  final int id;
  String _name;
  String _email;
  List<String> _role;
  List<String> _changed = [];
  final KuebikoHttpClient _httpClient;
  final CacheController _cacheController;

  KuebikoUser(this.id, this._name, this._email, this._role, this._httpClient, this._cacheController);

  static Future<List<User>> getAll(KuebikoHttpClient httpClient, CacheController cacheController) async {
    Uri uri = httpClient.config.generateApiUri('/users');
    Response res = await httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    List usersRaw = json['users'];
    return usersRaw.map((user) => KuebikoUser(
        user['id'],
        user['name'],
        user['email'],
        user['role'].cast<String>(),
        httpClient,
        cacheController
    )).toList();
  }

  static Future<User> currentUser(KuebikoHttpClient httpClient, CacheController cacheController) async {
    Uri uri = httpClient.config.generateApiUri('/user');
    Response res = await httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    Map userRaw = json['user'];
    return KuebikoUser(
        userRaw['id'],
        userRaw['name'],
        userRaw['email'],
        userRaw['role'].cast<String>(),
        httpClient,
        cacheController
    );
  }

  static Future<User> create(
      String email,
      String name,
      String password,
      List<String> role,
      String anilistName,
      String anilistToken,
      KuebikoHttpClient httpClient,
      CacheController cacheController
      ) async {
    Uri uri = httpClient.config.generateApiUri('/user/create');
    Response res = await httpClient.post(
        uri,
        data: {
          'email': email,
          'name': name,
          'password': password,
          'role': role.join(','),
          'anilist': jsonEncode({
            'name': anilistName,
            'token': anilistToken
          })
        }
    );
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    return KuebikoUser(json['user'], name, email, role, httpClient, cacheController);
  }

  void update(String password) {
    Uri uri = _httpClient.config.generateApiUri('/user/edit');

    Map data = {
      'password': password
    };
    _changed.forEach((String changedElement) {
      switch(changedElement){
        case 'name':
          data['name'] = _name;
          break;
        case 'email':
          data['email'] = _email;
          break;
        case 'role':
          data['role'] = _role;
          break;
      }
    });

    _httpClient.put(
        uri,
        data: data
    );
  }

  Future<void> delete(String password) async {
    Uri uri = _httpClient.config.generateApiUri('/user/delete');
    await _httpClient.delete(
        uri,
        data: {
          'password': password
        }
    );
  }

  void tokenDelete(int tokenId) {
    Uri uri = _httpClient.config.generateApiUri(
        '/token/delete',
        queryParameters: {
          'tokenid': tokenId.toString()
        }
    );
    _httpClient.delete(uri);
  }

  Future<List<Book>> unreadBooks() async {
    Uri uri = _httpClient.config.generateApiUri('/unread');
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    List<Book> books = [];

    for (Map book in json['books']) {
      books.add(
          KuebikoBook(
              book['id'],
              await this._cacheController.libraryCache.getById(book['library']),
              book['name'],
              _cacheController,
              _httpClient
          )
      );
    }
    return books;
  }

  Future<List<Book>> readingBooks() async {
    Uri uri = _httpClient.config.generateApiUri('/reading');
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    List<Book> books = [];

    for (Map book in json['books']) {
      books.add(
          KuebikoBook(
              book['id'],
              await this._cacheController.libraryCache.getById(book['library']),
              book['name'],
              _cacheController,
              _httpClient
          )
      );
    }
    return books;
  }

  Future<List<Book>> finishedBooks() async {
    Uri uri = _httpClient.config.generateApiUri('/finished');
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    List<Book> books = [];

    for (Map book in json['books']) {
      books.add(
          KuebikoBook(
              book['id'],
              await this._cacheController.libraryCache.getById(book['library']),
              book['name'],
              _cacheController,
              _httpClient
          )
      );
    }
    return books;
  }
  String getEmail() => _email;
  String getName() => _name;
  List<String> getRoles() => _role;
}