import 'series.dart';

abstract interface class SeriesCache {
  Future<Series> getById(String id);

  List<Series> getAll();

  Future<void> update();
}