import 'package:http/http.dart' as http;
import 'package:kuebiko_client/src/exception/client_upgrade_needed_exception.dart';
import 'package:kuebiko_client/src/exception/invalid_key_exception.dart';
import 'package:kuebiko_client/src/exception/missing_key_exception.dart';
import 'package:kuebiko_client/src/exception/server_maintenance_exception.dart';
import 'package:kuebiko_client/src/exception/server_upgrade_needed_exception.dart';
import 'dart:convert';
import 'package:kuebiko_client/src/kuebiko_config.dart';
import 'package:kuebiko_client/src/models/download.dart';

class KuebikoHttpClient extends http.BaseClient {

  final KuebikoConfig config;
  final http.Client _inner;

  KuebikoHttpClient(this.config, this._inner) {

  }

  _errorCheck(http.Response response){
    switch(response.statusCode){
      case 401:
        throw MissingKeyException();
      case 403:
        throw InvalidKeyException();
      case 426:
        Map json = jsonDecode(response.body);
        int ownVersion = int.parse(config.apiVersion.replaceAll('v', ''));
        int serverVersion = int.parse(json['version'].replaceAll('v',''));
        if(ownVersion > serverVersion){
          throw ServerUpgradeNeededException();
        } else {
          throw ClientUpgradeNeededException();
        }
      case 503:
        throw ServerMaintenanceModeException();
    }
  }

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    http.Response res = await _sendUnstreamed('GET', url, headers);
    _errorCheck(res);
    return res;
  }

  Future<KuebikoDownload> getFile(Uri url, {Map<String, String>? headers}) async {
    http.StreamedResponse response = await send(http.Request('GET', url));
    return KuebikoDownload(stream: response.stream, length: response.contentLength!);
  }


  @override
  Future<http.Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    http.Response res = await _sendUnstreamed('POST', url, headers, body, encoding);
    _errorCheck(res);
    return res;
  }


  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    http.Response res = await _sendUnstreamed('PUT', url, headers, body, encoding);
    _errorCheck(res);
    return res;
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    http.Response res = await _sendUnstreamed('PATCH', url, headers, body, encoding);
    _errorCheck(res);
    return res;
  }

  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    http.Response res = await _sendUnstreamed('DELETE', url, headers, body, encoding);
    _errorCheck(res);
    return res;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = config.appName + '/' +
        config.appVersion.toString() + '(KuebikoDartClient/' +
        config.libraryVersion.toString() + ') / ' + config.deviceName;
    if (config.apiKey != null) {
      request.headers['X-API-Key'] = config.apiKey!;
    }
    return _inner.send(request);
  }

  /// Sends a non-streaming [Request] and returns a non-streaming [Response].
  Future<http.Response> _sendUnstreamed(
      String method, Uri url, Map<String, String>? headers,
      [body, Encoding? encoding]) async {
    var request = http.Request(method, url);

    if (headers != null) request.headers.addAll(headers);
    if (encoding != null) request.encoding = encoding;
    if (body != null) {
      if (body is String) {
        request.body = body;
      } else if (body is List) {
        request.bodyBytes = body.cast<int>();
      } else if (body is Map) {
        request.bodyFields = body.cast<String, String>();
      } else {
        throw ArgumentError('Invalid request body "$body".');
      }
    }

    return http.Response.fromStream(await send(request));
  }
}