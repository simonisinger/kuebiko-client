library kuebiko_client;

import 'dart:async';

import 'package:http/http.dart' as http;
import 'src/caches/cache_controller.dart';
import 'src/interfaces/cache_controller.dart';
import 'src/kuebiko_config.dart';
import 'src/kuebiko_http_client.dart';
import 'src/models/mysql_config.dart';
import 'src/models/settings.dart';
import 'src/models/smtp_config.dart';
import 'src/models/user.dart';
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
export 'src/models/download.dart';
export 'src/models/client.dart';
export 'src/models/upload.dart';
export 'src/interfaces/book.dart';
export 'src/interfaces/cache_controller.dart';
export 'src/interfaces/library.dart';
export 'src/interfaces/library_cache.dart';
export 'src/interfaces/series_cache.dart';
export 'src/interfaces/user.dart';
export 'src/interfaces/client.dart';


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