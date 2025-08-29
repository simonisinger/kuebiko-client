import 'dart:convert';

import 'package:kuebiko_client/src/kuebiko_http_client.dart';
import 'package:dio/dio.dart';
import 'package:kuebiko_client/src/models/book.dart';

import '../interfaces/book.dart';
import '../interfaces/cache_controller.dart';

class Series {
  final int id;
  String _name;
  String _author;
  String _description;
  int _numberOfVolumes;
  String _publisher;
  String _language;
  String _genre;
  String _ageRating;
  String _type;
  List<String> _locked;
  final KuebikoHttpClient _httpClient;
  final CacheController _cacheController;

  Series(
      this.id,
      this._name,
      this._author,
      this._description,
      this._numberOfVolumes,
      this._publisher,
      this._language,
      this._genre,
      this._ageRating,
      this._type,
      this._locked,
      this._cacheController,
      this._httpClient
  );

  String getName() => this._name;
  String getAuthor() => this._author;
  String getDescription() => this._description;
  int getNumberOfVolumes() => this._numberOfVolumes;
  String getPublisher() => this._publisher;
  String getLanguage() => this._language;
  String getGenre() => this._genre;
  String getAgeRating() => this._ageRating;
  String getType() => this._type;

  static Future<List<Series>> getAll(CacheController cacheController, KuebikoHttpClient httpClient) async {
    Uri uri = httpClient.config.generateApiUri('/series');
    Response res = await httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    List seriesRaw = json['series'];
    return seriesRaw.map((seriesSingle) => Series(
        seriesSingle['id'],
        seriesSingle['name'],
        seriesSingle['author'],
        seriesSingle['description'],
        seriesSingle['number_of_volumes'],
        seriesSingle['publisher'],
        seriesSingle['language'],
        seriesSingle['genre'],
        seriesSingle['age_rating'],
        seriesSingle['type'],
        seriesSingle['locked'].cast<String>(),
        cacheController,
        httpClient
    )).toList();
  }

  static Future<Series> create({
    required String name,
    required String author,
    required String description,
    required int numberOfVolumes,
    required String publisher,
    required String language,
    required String genre,
    required String ageRating,
    required String type,
    required List<String> locked,
    required CacheController cacheController,
    required KuebikoHttpClient httpClient
  }) async {
    // TODO test method
    Uri uri = httpClient.config.generateApiUri('/series/create');
    Response res = await httpClient.post(
        uri,
        data: {
          'name': name,
          'author': author,
          'description': description,
          'number_of_volumes': numberOfVolumes,
          'publisher': publisher,
          'language': language,
          'genre': genre,
          'age_rating': ageRating,
          'type': type,
          'locked': locked
        }
    );
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());
    return Series(
        json['series'],
        name,
        author,
        description,
        numberOfVolumes,
        publisher,
        language,
        genre,
        ageRating,
        type,
        locked,
        cacheController,
        httpClient
    );
  }

  Series setName(String name){
    this._name = name;
    this.lockName();
    return this;
  }

  Series setAuthor(String author){
    this._author = author;
    this.lockAuthor();
    return this;
  }

  Series setDescription(String description){
    this._description = description;
    this.lockDescription();
    return this;
  }

  Series setNumberOfVolumes(int numberOfVolumes){
    this._numberOfVolumes = numberOfVolumes;
    this.lockNumberOfVolumes();
    return this;
  }

  Series setPublisher(String publisher){
    this._publisher = publisher;
    this.lockPublisher();
    return this;
  }

  Series setLanguage(String language){
    this._language = language;
    this.lockLanguage();
    return this;
  }

  Series setGenre(String genre){
    this._genre = genre;
    this.lockGenre();
    return this;
  }

  Series setAgeRating(String ageRating){
    this._ageRating = ageRating;
    this.lockAgeRating();
    return this;
  }

  Series setType(String type){
    this._type = type;
    this.lockType();
    return this;
  }

  void update(){
    // TODO test method
    Uri uri = _httpClient.config.generateApiUri('/series/update');
    _httpClient.put(
        uri,
        data: {
          'series': id,
          'name': _name,
          'author': _author,
          'description': _description,
          'number_of_volumes': _numberOfVolumes,
          'publisher': _publisher,
          'language': _language,
          'genre': _genre,
          'age_rating': _ageRating,
          'type': _type,
          'locked': _locked
        }
    );
  }
  
  Future<List<Book>> books(BookSorting sorting, SortingDirection direction) async{
    Uri uri = _httpClient.config.generateApiUri(
        '/series/' + id.toString() + '/books',
        queryParameters: {
          'sort': sorting.name,
          'direction': direction.name
        }
    );
    Response res = await _httpClient.get(uri);
    Map json = res.data is Map ? res.data : jsonDecode(res.data.toString());

    List<Book> books = [];

    for (Map book in json['books']) {
      books.add(
          KuebikoBook(
              book['id'],
              await this._cacheController.libraryCache.getById(book['library']),
              book['name'],
              _cacheController,
              _httpClient
          )
      );
    }
    return books;
  }

  Series unlockName() {
    this._locked.remove('name');
    return this;
  }

  Series unlockAuthor() {
    this._locked.remove('author');
    return this;
  }

  Series unlockDescription() {
    this._locked.remove('description');
    return this;
  }

  Series unlockNumberOfVolumes() {
    this._locked.remove('number_of_volumes');
    return this;
  }

  Series unlockPublisher() {
    this._locked.remove('publisher');
    return this;
  }

  Series unlockLanguage() {
    this._locked.remove('language');
    return this;
  }

  Series unlockGenre() {
    this._locked.remove('genre');
    return this;
  }

  Series unlockAgeRating() {
    this._locked.remove('age_rating');
    return this;
  }

  Series unlockType(){
    this._locked.remove('type');
    return this;
  }

  Series lockName(){
    if(!this._locked.contains('name')){
      this._locked.add('name');
    }
    return this;
  }

  Series lockAuthor(){
    if(!this._locked.contains('author')){
      this._locked.add('author');
    }
    return this;
  }

  Series lockDescription(){
    if(!this._locked.contains('description')){
      this._locked.add('description');
    }
    return this;
  }

  Series lockNumberOfVolumes(){
    if(!this._locked.contains('number_of_volumes')){
      this._locked.add('number_of_volumes');
    }
    return this;
  }

  Series lockPublisher(){
    if(!this._locked.contains('publisher')){
      this._locked.add('publisher');
    }
    return this;
  }

  Series lockLanguage(){
    if(!this._locked.contains('language')){
      this._locked.add('language');
    }
    return this;
  }

  Series lockGenre(){
    if(!this._locked.contains('genre')){
      this._locked.add('genre');
    }
    return this;
  }

  Series lockAgeRating(){
    if(!this._locked.contains('age_rating')){
      this._locked.add('age_rating');
    }
    return this;
  }

  Series lockType(){
    if(!this._locked.contains('type')){
      this._locked.add('type');
    }
    return this;
  }
}