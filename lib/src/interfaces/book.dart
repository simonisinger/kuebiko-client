import 'dart:typed_data';

import 'package:kuebiko_client/src/models/download.dart';

import '../models/progress.dart';

enum BookSorting {
  name,
  upload,
  published,
  author,
  number
}

enum SortingDirection {
  asc,
  desc
}

enum Formats {
  epub,
  ebz,
  pdf,
  azw3
}

abstract interface class Book {
  final int id;
  String name;

  Book(this.id, this.name);

  Future<KuebikoDownload> download(Formats format);

  Future<String> convert(Formats format);

  Future<String> convertStatus(String convertId);

  Future<void> delete();

  Future<Map> metadata();

  void renewMetadata();

  Future<Uint8List> cover();

  Future<void> setProgress(Progress progress);

  Future<Progress> getProgress();
}