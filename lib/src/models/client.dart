import 'dart:convert';

import 'package:http/http.dart' as http;

import '../caches/cache_controller.dart';
import '../exception/server_maintenance_exception.dart';
import '../interfaces/book.dart';
import '../interfaces/cache_controller.dart';
import '../interfaces/client.dart';
import '../interfaces/library.dart';
import '../interfaces/user.dart';
import '../kuebiko_config.dart';
import '../kuebiko_http_client.dart';
import 'book.dart';
import 'library.dart';
import 'user.dart';
import 'settings.dart';
import 'series.dart';

class KuebikoClient implements Client {

  final KuebikoConfig _config;
  late final KuebikoHttpClient _client;
  late final CacheController _cacheController;
  late final Settings _settings;

  bool _initialized = false;

  KuebikoClient(this._config) {
    _client = KuebikoHttpClient(_config, http.Client());
    _settings = Settings(_client);
    _cacheController = KuebikoCacheController(_client);

    _initialize();
  }

  _initialize() async {
    if(this._config.apiKey != null){
      await _cacheController.libraryCache.update();
      await _cacheController.seriesCache.update();
      this._initialized = true;
    }
  }

  // Creates an API token with the login credentials and returns a Client object
  static Future<KuebikoClient> login(KuebikoConfig config, String username, String password) async
  {
    KuebikoClient tmpClient;
    try {
      tmpClient = KuebikoClient(config);
      if(await tmpClient.status() != 'Running'){
        throw ServerMaintenanceModeException();
      }
    } catch(e){
      rethrow;
    }

    Uri loginUri = config.generateApiUri('/api-key');
    String encodedCredentials = base64.encode((username+':'+password).codeUnits);
    http.Response res = await tmpClient._client.get(
        loginUri,
        headers: {
          'Authorization': 'Basic ' + encodedCredentials
        }
    );
    Map resJson = jsonDecode(res.body);
    config = KuebikoConfig(
        appName: config.appName,
        appVersion: config.appVersion,
        baseUrl: config.baseUrl,
        deviceName: config.deviceName,
        apiKey: resJson['token']
    );
    return KuebikoClient(config);
  }

  // Returns the Kuebiko Config
  KuebikoConfig getConfig() => this._config;
  bool getInitialized() => this._initialized;

  Future<List<Book>> getBooks(BookSorting sorting, SortingDirection sortingDirection) async {
    await _checkInitialized();

    List<Book> books = await KuebikoBook.getBooks(sorting, sortingDirection, _cacheController, _client);
    return books;
  }

  _checkInitialized() async {
    final Duration waitDuration = Duration(milliseconds: 200);
    while(!this._initialized){
      await Future.delayed(waitDuration);
    }
  }

  Future<List<Library>> getLibraries() async {
    await _checkInitialized();
    return _cacheController.libraryCache.getAll();
  }

  Future<Library> createLibrary(String name, String path) => KuebikoLibrary.create(name, path, _cacheController, _client);

  Future<void> createFolder(String path) => KuebikoLibrary.createFolder(path, _client);
  Future<List<String>> getFolderContent(String path) => KuebikoLibrary.getFolderContent(path, _client);

  void scanAll() => KuebikoLibrary.scanAll(_client);

  void renewMetadataAll() => KuebikoLibrary.renewMetadataAll(_client);

  Future<Series> createSeries({
    required String name,
    required String author,
    required String description,
    required int numberOfVolumes,
    required String publisher,
    required String language,
    required String genre,
    required String ageRating,
    required String type,
    required List<String> locked
  }) => Series.create(
    name: name,
    author: author,
    description: description,
    numberOfVolumes: numberOfVolumes,
    publisher: publisher,
    language: language,
    genre: genre,
    ageRating: ageRating,
    type: type,
    locked: locked,
    cacheController: _cacheController,
    httpClient: _client,
  );

  Future<List<Series>> getAllSeries() async {
    await _checkInitialized();
    return this._cacheController.seriesCache.getAll();
  }

  Future<String> status() => Settings.status(_client);

  Future<Uri> docs() => Settings.docs(_client);

  Settings getSettings() => _settings;

  Future<User> currentUser() => KuebikoUser.currentUser(_client, _cacheController);

  Future<List<User>> getUsers() => KuebikoUser.getAll(_client, _cacheController);

  Future<User> createUser(
      String email,
      String name,
      String password,
      List<String> role,
      String anilistName,
      String anilistToken
      ) => KuebikoUser.create(
      email,
      name,
      password,
      role,
      anilistName,
      anilistToken,
      _client,
      _cacheController
  );
}