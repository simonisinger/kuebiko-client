import 'series.dart';

abstract interface class SeriesCache {
  Future<Series> getById(int id);

  List<Series> getAll();

  Future<void> update();
}