import '../interfaces/book.dart';

abstract interface class User {
  final int id;
  String _name;
  String _email;
  List<String> _role;

  User(this.id, this._name, this._email, this._role);

 void update(String password);

  Future<void> delete(String password);

  void tokenDelete(int tokenId);

  Future<List<Book>> unreadBooks();

  Future<List<Book>> readingBooks();

  Future<List<Book>> finishedBooks();
  String getEmail() => _email;
  String getName() => _name;
  List<String> getRoles() => _role;
}