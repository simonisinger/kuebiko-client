import '../interfaces/book.dart';

abstract interface class Series {

  String get id;
  String get name;
  String get author;
  String get description;
  int get numberOfVolumes;
  String get publisher;
  String get language;
  String get genre;
  String get ageRating;
  String get type;

  void set name(String name);

  void set author(String author);

  void set description(String description);

  void set numberOfVolumes(int numberOfVolumes);

  void set publisher(String publisher);

  void set language(String language);

  void set genre(String genre);

  void set ageRating(String ageRating);

  void set type(String type);

  Future<void> update();

  Future<List<Book>> books(BookSorting sorting, SortingDirection direction);

  Series unlockName();

  Series unlockAuthor();

  Series unlockDescription();

  Series unlockNumberOfVolumes();

  Series unlockPublisher();

  Series unlockLanguage();

  Series unlockGenre();

  Series unlockAgeRating();

  Series unlockType();

  Series lockName();

  Series lockAuthor();

  Series lockDescription();

  Series lockNumberOfVolumes();

  Series lockPublisher();

  Series lockLanguage();

  Series lockGenre();

  Series lockAgeRating();

  Series lockType();
}