import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:kuebiko_client/src/interfaces/book.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';


setupServer(Router app) async {
  final address = InternetAddress.loopbackIPv4;
  const port = 4040;
  Middleware middleware = createMiddleware(
      requestHandler: validateRequest
  );
  var handler = Pipeline().addMiddleware(middleware).addHandler(app);
  return await io.serve(handler, address, port);
}

Router registerRoutes(){
  Router app = Router();
  handleGet(app);
  handlePost(app);
  handleDelete(app);
  handlePut(app);
  return app;
}

Future<Response?> validateRequest(Request request) async {
  List<String> unsecuredRoutes = [
    '/v1/password-forget',
    '/v1/api-key',
    '/v1/status',
    '/v1/docs'
  ];
  if (!unsecuredRoutes.contains('/' + request.url.path)) {
    if (!request.headers.containsKey('X-API-Key')) {
      return Response(
          401,
          body: jsonEncode({
            "code": 401,
            "message": "Unauthorized Access, please add Header X-API-Key",
            "version": "v0.1"
          })
      );
    } else if (request.headers['X-API-Key'] != '3fa85f64-5717-4562-b3fc-2c963f66afa6') {
      return Response(
          403,
          body: jsonEncode({
            "code": 403,
            "message": "Forbidden Key is in use",
            "version": "v0.1"
          })
      );
    }
  }
}

Future<Map<String, dynamic>> decodeHttpRequestBody(Request request) async {
  String inputRaw = await utf8.decodeStream(request.read());
  Map<String, dynamic> formattedInput = {};
  List<String> fields = inputRaw.split('&');
  fields.forEach((element) {
    List<String> fieldList = element.split('=');
    String fieldContent = fieldList[1];
    List<String> valuesList = fieldContent.split(',');
    if (valuesList.length > 1) {
      formattedInput.addAll({fieldList[0]: valuesList});
    }
    formattedInput.addAll({fieldList[0]: fieldList[1]});
  });
  return formattedInput;
}

setErrorOfField(String fieldName) {
  return Response(
      422,
      body: jsonEncode({
        "code": 422,
        "message": "field: $fieldName of error",
        "version": "v0.1"
      })
  );
}

Future<void> handlePut(Router app) async {

  app.put('/v1/user/edit', (Request request) async {
    Map<String, dynamic> input = await decodeHttpRequestBody(request);
    if (input['password'] == null || input['password']!.isEmpty) {
      return setErrorOfField('password');
    }
    return Response.ok(jsonEncode({"code": 200, "user": 1, "version": "v0.1"}));
  });

  app.put('/v1/user/<user>/edit', (Request request, String user) async {
    if(int.tryParse(user) == null){
      return setErrorOfField('user');
    }
    return Response.ok(jsonEncode({"code": 200, "user": 1, "version": "v0.1"}));
  });

  app.put('/v1/convert', (Request request) async {
    if (request.url.queryParameters['library'] == null ||
        request.url.queryParameters['library'] != '1') {
      return setErrorOfField('library');
    }
    if (request.url.queryParameters['book'] == null ||
        request.url.queryParameters['book'] != '1') {
      return setErrorOfField('book');
    }

    if (request.url.queryParameters['library'] == null ||
        Formats.values
            .where((Formats element) =>
        element.name != request.url.queryParameters['library'])
            .length ==
            0) {
      return setErrorOfField('library');
    }
    return Response.ok(jsonEncode({
      "code": 200,
      "convertId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "version": "v0.1"
    }));
  });

  app.put('/v1/update', (Request request) async {
    Map<String, dynamic> httpBody = await decodeHttpRequestBody(request);
    if (httpBody['library'] == null ||
        int.tryParse(httpBody['library']!) == null) {
      return setErrorOfField('library');
    }

    if (httpBody['book'] == null || int.tryParse(httpBody['book']!) == null) {
      return setErrorOfField('book');
    }

    if (httpBody['series'] == null &&
        int.tryParse(httpBody['series']!) == null) {
      return setErrorOfField('series');
    }

    if (httpBody['number_of_volume'] == null &&
        int.tryParse(httpBody['number_of_volume']!) == null) {
      return setErrorOfField('number_of_volume');
    }
    if (!(httpBody['locked'] is List)) {
      return setErrorOfField('locked');
    }
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/book/metadata', (Request request) {

    if (request.url.queryParameters['library'] == null ||
        int.tryParse(request.url.queryParameters['library']!) == null) {
      return setErrorOfField('library');
    }

    if (request.url.queryParameters['book'] == null || int.tryParse(request.url.queryParameters['book']!) == null) {
      return setErrorOfField('book');
    }
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/series/update', (Request request) async {
    Map<String, dynamic> httpBody = await decodeHttpRequestBody(request);
    if (httpBody['series'] == null ||
        int.tryParse(httpBody['series']!) == null) {
      return setErrorOfField('series');
    }

    if (httpBody['locked'] == null || !(httpBody['book']! is List)) {
      return setErrorOfField('locked');
    }
    return Response.ok(jsonEncode({"code": 200, "series": 1, "version": "v0.1"}));
  });

  app.put('/v1/library/update', (Request request) async {
    Map<String, dynamic> httpBody = await decodeHttpRequestBody(request);
    if (httpBody['library'] == null ||
        int.tryParse(httpBody['library']!) == null) {
      return setErrorOfField('library');
    }
    return Response.ok(jsonEncode({"code": 200, "library": 1, "version": "v0.1"}));
  });

  app.put('/v1/library/scan', (Request request) async {
    if (request.url.queryParameters['library'] == null ||
        int.tryParse(request.url.queryParameters['library']!) == null) {
      return setErrorOfField('library');
    }
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/library/metadata', (Request request) async {
    if (request.url.queryParameters['library'] == null ||
        int.tryParse(request.url.queryParameters['library']!) == null) {
      return setErrorOfField('library');
    }
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/scan', (Request request) async {
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/renewMetadata', (Request request) async {
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/folder', (Request request) async {
    if (request.url.queryParameters['folder'] == null ||
        request.url.queryParameters['folder']!.isEmpty) {
      return setErrorOfField('folder');
    }
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });

  app.put('/v1/<library>/<book>/progress', (Request request, String library, String book) async {

    if(int.tryParse(library) == null){
      return setErrorOfField('library');
    }

    if(int.tryParse(book) == null){
      return setErrorOfField('book');
    }

    Map<String, dynamic> httpBody = await decodeHttpRequestBody(request);
    if (httpBody['library'] == null ||
        int.tryParse(httpBody['library']!) == null) {
      return setErrorOfField('library');

    }

    if (httpBody['book'] == null || int.tryParse(httpBody['book']!) == null) {
      return setErrorOfField('book');
    }

    if (httpBody['reading_page'] == null ||
        double.tryParse(httpBody['reading_page']!) == null) {
      return setErrorOfField('reading_page');
    }
    return Response.ok(jsonEncode({"code": 200, "version": "v0.1"}));
  });
}

void handleDelete(Router app) {
  app.delete('/v1/user/delete', (Request request){
    if (request.url.queryParameters['password'] == null ||
        request.url.queryParameters['password'] != 'test123') {
      return setErrorOfField('password');
    }
    return Response.ok(
        jsonEncode({"code": 200, "user": 1, "version": "v0.1"})
    );
  });

  app.delete('/v1/user/<user>/delete', (Request request, String user){
    if(int.tryParse(user) == null){
      return setErrorOfField('user');
    }
    return Response.ok(
        jsonEncode({"code": 200, "user": int.parse(user), "version": "v0.1"})
    );
  });

  app.delete('/v1/user/delete', (Request request){
    if (request.url.queryParameters['password'] == null) {
      return setErrorOfField('token');
    }
    return Response.ok(
        jsonEncode({
          "code": 200,
          "token": int.parse(request.url.queryParameters['token']!),
          "version": "v0.1"
        })
    );
  });

  app.delete('/v1/token/delete', (Request request){
    if (request.url.queryParameters['token'] == null ||
        int.tryParse(request.url.queryParameters['token']!) != null) {
      return setErrorOfField('token');
    }
    return Response.ok(
        jsonEncode({
          "code": 200,
          "token": int.parse(request.url.queryParameters['token']!),
          "version": "v0.1"
        })
    );
  });

  app.delete('/v1/delete', (Request request){
    if (request.url.queryParameters['library'] == null ||
        int.tryParse(request.url.queryParameters['library']!) == null) {
      return setErrorOfField('library');
    }

    if (request.url.queryParameters['book'] == null ||
        int.tryParse(request.url.queryParameters['book']!) == null) {
      return setErrorOfField('book');
    }
    return Response.ok(
        jsonEncode({"code": 200, "version": "v0.1"})
    );
  });

  app.delete('/v1/series/delete', (Request request){
    if (request.url.queryParameters['series'] == null ||
        int.tryParse(request.url.queryParameters['series']!) == null) {
      return setErrorOfField('series');
    }
    return Response.ok(
        jsonEncode({"code": 200, "version": "v0.1"})
    );
  });
}

void handlePost(Router app) async {

  app.post('/v1/user/create', (Request request) async {
    Map httpBody = await decodeHttpRequestBody(request);

    if (httpBody['email'] == null || !(httpBody['email'] is String)) {
      return setErrorOfField('email');
    }

    if (httpBody['name'] == null || !(httpBody['name'] is String)) {
      return setErrorOfField('name');
    }

    if (httpBody['password'] == null || !(httpBody['password'] is String)) {
      return setErrorOfField('password');
    }

    if (httpBody['role'] == null) {
      return setErrorOfField('role');
    }

    return Response.ok(
        jsonEncode({"code": 200, "user": 1, "version": "v0.1"})
    );
  });

  app.post('/v1/upload', (Request request){

    return Response.ok(
        jsonEncode({
          "code": 200,
          "bookId": 1,
          "bookname": "string",
          "version": "v0.1"
        })
    );
  });

  app.post('/v1/series/create', (Request request) async {
    Map httpBody = await decodeHttpRequestBody(request);

    if (httpBody['locked'] == null || !(httpBody['locked'] is List)) {
      return setErrorOfField('locked');
    }
    return Response.ok(
        jsonEncode({"code": 200, "series": 1, "version": "v0.1"})
    );
  });

  app.post('/v1/library/create', (Request request) async {

    Map httpBody = await decodeHttpRequestBody(request);
    if (httpBody['name'] == null || !(httpBody['name'] is String)) {
      return setErrorOfField('name');
    }

    if (httpBody['path'] == null || !(httpBody['path'] is String)) {
      return setErrorOfField('path');
    }

    return Response.ok(
        jsonEncode({"code": 200, "library": 1, "version": "v0.1"})
    );
  });

  app.post('/v1/setup', (Request request) async {
    Map httpBody = await decodeHttpRequestBody(request);
    if (httpBody['smtp'] == null) {
      return setErrorOfField('smtp');
    }

    if (httpBody['mysql'] == null) {
      return setErrorOfField('mysql');
    }

    if (httpBody['scan_interval'] == null ||
        int.tryParse(httpBody['scan_interval']!) == null) {
      return setErrorOfField('scan_interval');
    }

    if (httpBody['admin'] == null) {
      return setErrorOfField('admin');
    }

    if (httpBody['anilist_token'] == null ||
        !(httpBody['anilist_token'] is String)) {
      return setErrorOfField('anilist_token');
    }

    if (httpBody['url'] == null || !(httpBody['url'] is String)) {
      return setErrorOfField('url');
    }
    return Response.ok(
        jsonEncode({"code": 200, "version": "v0.1"})
    );
  });
  app.post('/v1/settings', (Request request){
    return Response.ok(
        jsonEncode({"code": 200, "version": "v0.1"})
    );
  });
}

void handleGet(Router app) {
  app.get('/v1/api-key', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "token": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
          "version": "v0.1"
        })
    );
  });

  app.get('/v1/users', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "users": [
            {
              "id": 1,
              "name": "string",
              "email": "user@example.com",
              "role": ["Admin"]
            }
          ],
          "version": "v0.1"
        })
    );
  });

  app.get('/v1/user', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "user": {
            "id": 0,
            "email": "user@example.com",
            "name": "string",
            "role": ["Admin"],
            "anilist": {"name": "string"}
          },
          "version": "v0.1"
        })
    );
  });

  app.get('/v1/devices', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "devices": [
            {"id": 1, "client": "string", "created": "2022-01-23"}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/password-forget', (Request request){
    return Response.ok(
        jsonEncode(
            {"code": 200, "version": "v0.1"}
        )
    );
  });
  app.get('/v1/download', (Request request){
    if(!request.url.queryParameters.containsKey('library') || int.tryParse(request.url.queryParameters['library']!) == null){
      return setErrorOfField('library');
    }

    if(!request.url.queryParameters.containsKey('book') || int.tryParse(request.url.queryParameters['book']!) == null){
      return setErrorOfField('book');
    }

    File epubFile = File('assets/pg84.epub');

    return Response.ok(
        epubFile.readAsStringSync(),
        headers: {
          'Content-Type': 'application/epub+zip'
        }
    );
  });
  app.get('/v1/convert/status', (Request request){
    if (request.url.queryParameters['convertId'] == null) {
      return setErrorOfField('convertId');
    }

    return Response.ok(
        jsonEncode({"code": 200, "status": "waiting", "version": "v0.1"})
    );
  });
  app.get('/v1/metadata', (Request request){
    if (request.url.queryParameters['library'] == null ||
        int.tryParse(request.url.queryParameters['library']!) == null) {
      return setErrorOfField('library');
    }

    if (request.url.queryParameters['book'] == null ||
        int.tryParse(request.url.queryParameters['book']!) == null) {
      return setErrorOfField('book');
    }

    return Response.ok(
        jsonEncode({
          "code": 200,
          "book": {
            "name": "string",
            "author": "string",
            "description": "string",
            "series": {"id": 1, "name": "string"},
            "number_of_volume": 1,
            "publisher": "string",
            "language": "string",
            "genre": "string",
            "tag": "string",
            "age_rating": "string",
            "release_date": "2022-01-23",
            "type": "Light Novel",
            "locked": ["name"]
          },
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/books', (Request request){
    if (request.url.queryParameters['sort'] == null ||
        BookSorting.values.contains(request.url.queryParameters['sort']!)) {
      return setErrorOfField('sort');
    }

    if (request.url.queryParameters['direction'] == null || SortingDirection.values.contains(request.url.queryParameters['direction']!)) {
      return setErrorOfField('direction');
    }

    return Response.ok(
        jsonEncode({
          "code": 200,
          "books": [
            {"id": 1, "name": "string", "path": "string", "library": 1}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/library/<library>/books', (Request request, String library){
    if(int.tryParse(library) == null){
      return setErrorOfField('library');
    }

    if (request.url.queryParameters['sort'] == null ||
        BookSorting.values.contains(request.url.queryParameters['sort']!)) {
      return setErrorOfField('sort');
    }

    if (request.url.queryParameters['direction'] == null ||
        SortingDirection.values
            .contains(request.url.queryParameters['direction']!)) {
      return setErrorOfField('direction');
    }

    return Response.ok(
        jsonEncode({
          "code": 200,
          "books": [
            {"id": 1, "name": "string", "path": "string", "library": 1}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/series/<series>/books', (Request request, String series){
    if (int.tryParse(series) == null) {
      return setErrorOfField('series');
    }

    if (request.url.queryParameters['sort'] == null ||
        BookSorting.values.contains(request.url.queryParameters['sort']!)) {
      return setErrorOfField('sort');
    }

    if (request.url.queryParameters['direction'] == null ||
        SortingDirection.values
            .contains(request.url.queryParameters['direction']!)) {
      return setErrorOfField('direction');
    }

    return Response.ok(
        jsonEncode({
          "code": 200,
          "books": [
            {"id": 0, "name": "string", "path": "string", "library": 1}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/cover', (Request request){
    if (request.url.queryParameters['library'] == null ||
        int.tryParse(request.url.queryParameters['library']!) == null) {
      return setErrorOfField('library');
    }
    if (request.url.queryParameters['book'] == null ||
        int.tryParse(request.url.queryParameters['book']!) == null) {
      return setErrorOfField('book');
    }

    File coverFile = File(Directory.current.path + Platform.pathSeparator + 'test' + Platform.pathSeparator + 'assets' + Platform.pathSeparator + 'pg84.cover.medium.jpg');
    Uint8List content = coverFile.readAsBytesSync();
    return Response.ok(
        content,
        headers: {
          'Content-Type':  'image/jpeg'
        }
    );
  });
  app.get('/v1/series', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "series": [
            {
              "id": 1,
              "name": "string",
              "author": "string",
              "description": "string",
              "number_of_volumes": 0,
              "publisher": "string",
              "language": "string",
              "genre": "string",
              "age_rating": "string",
              "type": "Light Novel",
              "locked": ["name"]
            }
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/<library>/series', (Request request, String library){
    if (int.tryParse(library) == null) {
      return setErrorOfField('library');
    }

    return Response.ok(
        jsonEncode({
          "code": 200,
          "series": [
            {
              "id": 1,
              "name": "string",
              "author": "string",
              "description": "string",
              "number_of_volumes": 0,
              "publisher": "string",
              "language": "string",
              "genre": "string",
              "age_rating": "string",
              "type": "Light Novel",
              "locked": ["name"]
            }
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/library', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "library": [
            {"id": 1, "name": "string", "path": "string"}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/folder', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "child": ["string"],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/<library>/<book>/progress', (Request request, String library, String book){
    if(int.tryParse(library) == null){
      return setErrorOfField('library');
    }
    if(int.tryParse(book) == null){
      return setErrorOfField('book');
    }
    return Response.ok(
        jsonEncode({
          "code": 200,
          "reading_page": 1,
          "max_page": 150,
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/unread', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "books": [
            {"id": 1, "library": 1, "name": "string"}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/reading', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "books": [
            {"id": 1, "library": 1, "name": "string"}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/finished', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "books": [
            {"id": 1, "library": 1, "name": "string"}
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/tasks', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "tasks": [
            {
              "id": 0,
              "description": "string"
            }
          ],
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/settings', (Request request){
    return Response.ok(
        jsonEncode({
          "code": 200,
          "settings": {
            "smtp": {
              "host": "string",
              "port": 0,
              "username": "string",
              "encryption": "TLS"
            },
            "scan_interval": 900
          },
          "version": "v0.1"
        })
    );
  });
  app.get('/v1/status', (Request request){
    return Response.ok(
        jsonEncode({"code": 200, "state": "Running", "version": "v0.1"})
    );
  });
  app.get('/v1/docs', (Request request){
    return Response.ok(
        jsonEncode({"code": 200, "doc": "string", "version": "v0.1"})
    );
  });
}
