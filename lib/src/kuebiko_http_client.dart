import 'package:dio/dio.dart';
import 'package:kuebiko_client/src/exception/client_upgrade_needed_exception.dart';
import 'package:kuebiko_client/src/exception/file_not_found_exception.dart';
import 'package:kuebiko_client/src/exception/invalid_key_exception.dart';
import 'package:kuebiko_client/src/exception/missing_key_exception.dart';
import 'package:kuebiko_client/src/exception/server_maintenance_exception.dart';
import 'package:kuebiko_client/src/exception/server_upgrade_needed_exception.dart';
import 'dart:convert';
import 'package:kuebiko_client/src/kuebiko_config.dart';
import 'package:kuebiko_client/src/models/download.dart';

class KuebikoHttpClient {
  final KuebikoConfig config;
  late final Dio _dio;

  KuebikoHttpClient(this.config) {
    _dio = Dio();

    // Configure interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['User-Agent'] = config.appName + '/' +
              config.appVersion.toString() + '(KuebikoDartClient/' +
              config.libraryVersion.toString() + ') / ' + config.deviceName;
          if (config.apiKey != null) {
            options.headers['X-API-Key'] = config.apiKey!;
          }
          handler.next(options);
        },
        onError: (error, handler) {
          _errorCheck(error);
          handler.next(error);
        },
      ),
    );
  }

  void _errorCheck(DioException error) {
    final statusCode = error.response?.statusCode;
    switch (statusCode) {
      case 401:
        throw MissingKeyException();
      case 403:
        throw InvalidKeyException();
      case 404:
        throw FileNotFoundException();
      case 426:
        Map json = error.response?.data is Map 
            ? error.response!.data 
            : jsonDecode(error.response?.data ?? '{}');
        int ownVersion = int.parse(config.apiVersion.replaceAll('v', ''));
        int serverVersion = int.parse(json['version'].replaceAll('v', ''));
        if (ownVersion > serverVersion) {
          throw ServerUpgradeNeededException();
        } else {
          throw ClientUpgradeNeededException();
        }
      case 503:
        throw ServerMaintenanceModeException();
    }
  }

  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      return await _dio.get(
        url.toString(),
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  Future<KuebikoDownload> getFile(Uri url, {Map<String, String>? headers}) async {
    try {
      final response = await _dio.get<ResponseBody>(
        url.toString(),
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
      );
      return KuebikoDownload(
        stream: response.data!.stream,
        length: int.parse(response.headers.value('content-length') ?? '0'),
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  Future<Response> post(Uri url,
      {Map<String, String>? headers, dynamic data}) async {
    try {
      return await _dio.post(
        url.toString(),
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  Future<Response> put(Uri url,
      {Map<String, String>? headers, dynamic data}) async {
    try {
      return await _dio.put(
        url.toString(),
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  Future<Response> patch(Uri url,
      {Map<String, String>? headers, dynamic data}) async {
    try {
      return await _dio.patch(
        url.toString(),
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  Future<Response> delete(Uri url,
      {Map<String, String>? headers, dynamic data}) async {
    try {
      return await _dio.delete(
        url.toString(),
        data: data,
        options: Options(headers: headers),
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  Future<Response> uploadWithProgress(
    String url,
    FormData formData, {
    Map<String, String>? headers,
    required void Function(int sent, int total) onSendProgress,
  }) async {
    try {
      return await _dio.post(
        url,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      _errorCheck(e);
      rethrow;
    }
  }

  void close() {
    _dio.close();
  }
}