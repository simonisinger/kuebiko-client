import '../../kuebiko_client.dart';

abstract interface class Client {
  // Returns the Kuebiko Config
  KuebikoConfig getConfig();
  bool getInitialized();

  Future<List<Book>> getBooks(BookSorting sorting, SortingDirection sortingDirection);

  Future<List<Library>> getLibraries();

  Future<Library> createLibrary(String name, String path);

  Future<void> createFolder(String path);
  Future<List<String>> getFolderContent(String path);

  void scanAll();

  void renewMetadataAll();

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
  });

  Future<List<Series>> getAllSeries();

  Future<String> status();

  Future<Uri> docs();

  Settings getSettings();

  Future<User> currentUser();

  Future<List<User>> getUsers();

  Future<User> createUser(
      String email,
      String name,
      String password,
      List<String> role,
      String anilistName,
      String anilistToken
  );
}