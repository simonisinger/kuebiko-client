import 'package:kuebiko_client/src/models/series.dart';

abstract interface class SeriesCache {
  Future<Series> getById(int id);

  List<Series> getAll();

  Future<void> update();
}