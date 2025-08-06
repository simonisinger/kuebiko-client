import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart';
import 'package:kuebiko_client/kuebiko_client.dart';
import 'package:kuebiko_client/src/models/upload.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:test/test.dart';
import 'package:version/version.dart';

import 'server.dart';
KuebikoClient? client;
void main() async {
  HttpServer? server;

  KuebikoConfig config = KuebikoConfig(
      deviceName: 'testDevice',
      baseUrl: Uri(
          scheme: 'http',
          host: InternetAddress.loopbackIPv4.host,
          port: 4040
      ),
      appVersion: Version(0, 1, 0),
      appName: 'TestApp'
  );
  setUp(() async {
    Router router = registerRoutes();
    server = await setupServer(router);
  });
  tearDown(() async {
    await server!.close();
    server = null;
    client = null;
  });
  test('books', () async {
    client = await KuebikoClient.login(
        config,
        'test',
        'test'
    );
    List<Book> books = await client!.getBooks(BookSorting.name, SortingDirection.asc);
    expect(books.length, 1);

    Book book = books.first;
    book.renewMetadata();
    Progress progress = await book.getProgress();
    expect(progress.maxPage, 150);
    expect(progress.currentPage, 1);

    await book.setProgress(progress);
    Map metadata = await book.metadata();
    expect(metadata['name'], 'string');
    expect(metadata['author'], 'string');
    expect(metadata['description'], 'string');
    expect(metadata['series'].runtimeType, Series);
    expect(metadata['number_of_volume'], 1);
    expect(metadata['publisher'], 'string');
    expect(metadata['language'], 'string');
    expect(metadata['genre'], 'string');
    expect(metadata['tag'], 'string');
    expect(metadata['age_rating'], 'string');
    expect(metadata['release_date'], '2022-01-23');
    expect(metadata['type'], 'Light Novel');
    expect(metadata['locked'].runtimeType, List);
    expect(metadata['locked'][0], 'name');

    String convertId = await book.convert(Formats.epub);
    expect(convertId, '3fa85f64-5717-4562-b3fc-2c963f66afa6');

    String convertStatus = await book.convertStatus(convertId);
    expect(convertStatus, 'waiting');
    book.delete();
    book.renewMetadata();
    Uint8List image = await book.cover();
    expect(image.runtimeType, Image);
    List<Library> libraries = await client!.getLibraries();
    File file = File(Directory.current.path + Platform.pathSeparator + 'test' + Platform.pathSeparator + 'assets' + Platform.pathSeparator + 'pg84.epub');
    KuebikoUpload upload = await libraries.first.upload('pg84.epub', BookMeta(
        name: 'pg84',
        volNumber: 1,
        releaseDate: DateTime.now(),
        author: 'test',
        language: 'en',
        maxPage: 255
    ),file.openRead(), file.lengthSync());
    book = await upload.book;
    expect(book.runtimeType, Book);
  });

  test('setup', () async {
    KuebikoConfig config = KuebikoConfig(
        deviceName: 'testDevice',
        baseUrl: Uri(
            scheme: 'http',
            host: InternetAddress.loopbackIPv4.host,
            port: 4040
        ),
        appVersion: Version(0, 1, 0),
        appName: 'TestApp',
        apiKey: '3fa85f64-5717-4562-b3fc-2c963f66afa6'
    );
    await setup(
        config: config,
        smtpConfig: SmtpConfig(
            host: Uri.parse('localhost'),
            port: 25,
            username: 'testuser',
            password: 'testpass',
            encryption: 'TLS'
        ),
        mysqlConfig: MysqlConfig(
            host: 'localhost',
            port: 3306,
            username: 'test',
            password: 'test',
            database: 'testDB'
        ),
        scanInterval: 900,
        url: Uri.parse('http://localhost:4040'),
        anilistToken: '435435423532',
        adminUsername: 'admin',
        adminEmail: 'admin@example.com',
        adminPassword: 'test123'
    );
  });

  test('settings', () async {
    client = await KuebikoClient.login(
        config,
        'test',
        'test'
    );
    while(!client!.getInitialized()){
      await Future.delayed(Duration(milliseconds: 50));
    }
    Settings settings = client!.getSettings();
    List<Task> tasks = await settings.tasks();
    String status = await client!.status();
    await settings.get();
  });

  test('library', () async {
    client = await KuebikoClient.login(
        config,
        'test',
        'test'
    );
    List<Library> libraries = await client!.getLibraries();
    Library library = libraries.first;
    library.renewMetadata();
    library.delete();
    library.scan();
    library.update();
    List<Series> series = await library.series();
    List<Book> books = await library.books(BookSorting.name, SortingDirection.asc);
    client!.scanAll();
    client!.renewMetadataAll();
    await client!.createFolder('/test');
    await client!.getFolderContent('/test');
    await client!.createLibrary('test123', '/mnt');
  });

  test('series', () async {
    client = await KuebikoClient.login(
        config,
        'test',
        'test'
    );
    List<Series> series = await client!.getAllSeries();
    Series seriesSingle = series.single;
    await seriesSingle.books(BookSorting.name, SortingDirection.asc);
  });

  test('user', () async {
    client = await KuebikoClient.login(
        config,
        'test',
        'test'
    );
    while(!client!.getInitialized()) {
      await Future.delayed(Duration(milliseconds: 50));
    }
    User currentUser = await client!.currentUser();
    currentUser.update('test');
    currentUser.delete('test');
    currentUser.tokenDelete(1);
    await currentUser.finishedBooks();
    await currentUser.readingBooks();
    await currentUser.unreadBooks();

    await client!.getUsers();
    await client!.createUser('test@example.com', 'exampleUsername', 'test1234', ['admin'], 'anilistName', 'anilistToken');
  });
}
