import 'dart:convert';

import 'package:kuebiko_client/src/exception/no_parameter_exception.dart';
import 'package:kuebiko_client/src/exception/no_smtp_password_exception.dart';
import 'package:kuebiko_client/src/kuebiko_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:kuebiko_client/src/models/mysql_config.dart';
import 'package:kuebiko_client/src/models/smtp_config.dart';
import 'package:kuebiko_client/src/models/task.dart';

import '../interfaces/user.dart';

class Settings {
  final KuebikoHttpClient _httpClient;

  Settings(this._httpClient);

  // Returns the State of the Server as a String
  static Future<String> status(KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri('/status');
    http.Response res = await httpClient.get(uri);
    return jsonDecode(res.body)['state'];
  }

  // Returns the Url to the Docs document
  static Future<Uri> docs(KuebikoHttpClient httpClient) async {
    // TODO test method
    Uri uri = httpClient.config.generateApiUri('/docs');
    http.Response res = await httpClient.get(uri);
    return Uri.parse(jsonDecode(res.body)['doc']);
  }

  /**
   * Returns the server settings
   */
  Future<Map<String,dynamic>> get() async {
    Uri uri = _httpClient.config.generateApiUri('/settings');
    http.Response res = await _httpClient.get(uri);
    Map json = jsonDecode(res.body);
    Map<String, dynamic> settingsRaw = json['settings'];
    SmtpConfig smtpConfig = SmtpConfig(
        host: Uri.parse(settingsRaw['smtp']['host']),
        port: settingsRaw['smtp']['port'],
        username: settingsRaw['smtp']['username'],
        encryption: settingsRaw['smtp']['encryption']
    );
    settingsRaw['smtp'] = smtpConfig;
    return settingsRaw;
  }

  // update the settings
  Future<void> update({SmtpConfig? smtpConfig, int? scanInterval, String? anilistToken}) async {
    if(smtpConfig == null && scanInterval == null && anilistToken == null){
      throw NoParameterException();
    }
    Map<String, dynamic> settings = {};
    if(smtpConfig != null){
      if(smtpConfig.password == null){
        throw NoSmtpPasswordException();
      }
      settings['smtp'] = {
        'host': smtpConfig.host.host,
        'port': smtpConfig.port,
        'username': smtpConfig.username,
        'password': smtpConfig.password,
        'encryption': smtpConfig.encryption
      };
    }

    if(scanInterval != null){
      settings['scan_interval'] = scanInterval;
    }

    if(anilistToken != null){
      settings['anilist_token'] = anilistToken;
    }

    Uri uri = _httpClient.config.generateApiUri('/settings');

    await _httpClient.post(uri, body: settings);
  }

  // executes the setup command
  static Future<void> setup({
    required KuebikoHttpClient httpClient,
    required SmtpConfig smtpConfig,
    required MysqlConfig mysqlConfig,
    required int scanInterval,
    required Uri url,
    required String anilistToken,
    required User adminUser,
    required String adminPassword,
    String? adminAnilistName,
    String? adminAnilistToken
  }) async {
    Uri uri = httpClient.config.generateApiUri('/setup');

    if(smtpConfig.password == null || smtpConfig.password!.isEmpty){
      throw NoSmtpPasswordException();
    }

    Map adminMap = {
      'email': adminUser.getEmail(),
      'name': adminUser.getName(),
      'password': adminPassword
    };

    if (adminAnilistName != null && adminAnilistToken != null) {
      adminMap['anilist'] = {
        'name': adminAnilistName,
        'token': adminAnilistToken
      };
    }

    http.Response res = await httpClient.post(
        uri,
        body: {
          'scan_interval': scanInterval.toString(),
          'smtp': jsonEncode({
            'host': smtpConfig.host.toString(),
            'port': smtpConfig.port.toString(),
            'username': smtpConfig.username,
            'password': smtpConfig.password,
            'encryption': smtpConfig.encryption
          }),
          'url': url.toString(),
          'mysql': jsonEncode({
            'host': mysqlConfig.host.toString(),
            'port': mysqlConfig.port.toString(),
            'username': mysqlConfig.username,
            'password': mysqlConfig.password,
            'database': mysqlConfig.database
          }),
          'admin': jsonEncode(adminMap),
          'anilist_token': anilistToken
        }
    );
    print(res.body);
  }

  Future<List<Task>> tasks() async {
    Uri uri = _httpClient.config.generateApiUri('/tasks');
    http.Response res = await _httpClient.get(uri);
    Map json = jsonDecode(res.body);
    List tasksRaw = json['tasks'];
    return tasksRaw.map((e) => Task(
        id: e['id'],
        description: e['description']
    )).toList();
  }


}