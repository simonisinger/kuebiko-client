library kuebiko_client;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:kuebiko_client/src/caches/cache_controller.dart';
import 'package:kuebiko_client/src/exception/server_maintenance_exception.dart';
import 'package:kuebiko_client/src/interfaces/book.dart';
import 'package:kuebiko_client/src/interfaces/cache_controller.dart';
import 'package:kuebiko_client/src/interfaces/library.dart';
import 'package:kuebiko_client/src/interfaces/user.dart';
import 'package:kuebiko_client/src/kuebiko_config.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';
import 'package:kuebiko_client/src/models/book.dart';
import 'package:kuebiko_client/src/models/library.dart';
import 'package:kuebiko_client/src/models/mysql_config.dart';
import 'package:kuebiko_client/src/models/series.dart';
import 'package:kuebiko_client/src/models/settings.dart';
import 'package:kuebiko_client/src/models/smtp_config.dart';
import 'package:kuebiko_client/src/models/user.dart';
export 'src/models/user.dart' show KuebikoUser;
export 'src/models/book.dart' show KuebikoBook;
export 'src/kuebiko_config.dart' show KuebikoConfig;
export 'src/models/library.dart' show KuebikoLibrary;
export 'src/models/mysql_config.dart' show MysqlConfig;
export 'src/models/series.dart' show Series;
export 'src/models/settings.dart' show Settings;
export 'src/models/smtp_config.dart' show SmtpConfig;
export 'src/models/progress.dart' show Progress;
export 'src/models/task.dart' show Task;
export 'src/models/book_meta.dart' show BookMeta;
export 'src/interfaces/book.dart';
export 'src/interfaces/cache_controller.dart';
export 'src/interfaces/library.dart';
export 'src/interfaces/library_cache.dart';
export 'src/interfaces/series_cache.dart';
export 'src/interfaces/user.dart';

class KuebikoClient {

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


Future<void> setup({
  required KuebikoConfig config,
  required SmtpConfig smtpConfig,
  required MysqlConfig mysqlConfig,
  required int scanInterval,
  required Uri url,
  required String anilistToken,
  required String adminUsername,
  required String adminEmail,
  required String adminPassword,
  String? adminAnilistName,
  String? adminAnilistToken
}) async {

  KuebikoHttpClient httpClient = KuebikoHttpClient(config, http.Client());
  CacheController cacheController = KuebikoCacheController(httpClient);
  KuebikoUser adminUser = KuebikoUser(
      0,
      adminUsername,
      adminEmail,
      ['admin'],
      httpClient,
      cacheController
  );
  return await Settings.setup(
      httpClient: httpClient,
      smtpConfig: smtpConfig,
      mysqlConfig: mysqlConfig,
      scanInterval: scanInterval,
      url: url,
      anilistToken: anilistToken,
      adminUser: adminUser,
      adminPassword: adminPassword,
      adminAnilistName: adminAnilistName,
      adminAnilistToken: adminAnilistToken
  );
}