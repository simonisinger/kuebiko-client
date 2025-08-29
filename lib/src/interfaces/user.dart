import '../interfaces/book.dart';

abstract interface class User {
  final int id;
  String _name;
  String _email;
  List<String> _role;

  User(this.id, this._name, this._email, this._role);

  Future<void> update(String passwords);

  Future<void> delete(String password);

  void tokenDelete(int tokenId);

  Future<List<Book>> unreadBooks();

  Future<List<Book>> readingBooks();

  Future<List<Book>> finishedBooks();

  String get email => _email;
  String get name => _name;
  List<String> get roles => _role;
  void set roles(List<String> roles);
  void set name(String name);
  void set email(String email);
  void set newPassword(String newPassword);
}