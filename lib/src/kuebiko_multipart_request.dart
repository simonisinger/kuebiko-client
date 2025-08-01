import 'package:http/http.dart' as http;
import 'package:http/src/utils.dart';
import 'dart:async';

import 'package:kuebiko_client/src/kuebiko_http_client.dart';

class KuebikoMultipartRequest extends http.MultipartRequest {

  final KuebikoHttpClient client;
  KuebikoMultipartRequest(String method, this.client, Uri url) : super(method, url);

  @override
  Future<http.StreamedResponse> send() async {
    try {
      http.StreamedResponse response = await client.send(this);
      var stream = onDone(response.stream, client.close);
      return http.StreamedResponse(http.ByteStream(stream), response.statusCode,
          contentLength: response.contentLength,
          request: response.request,
          headers: response.headers,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
          reasonPhrase: response.reasonPhrase);
    } catch (_) {
      rethrow;
    }
  }
}