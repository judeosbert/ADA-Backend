import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/Dependency.dart';

class DbUtils {
  static TriValues<String> getPackageDetailsFrom(String completePackage) {
    if (completePackage == null || completePackage.isEmpty) {
      return TriValues();
    }

    final parts = completePackage.split(":");
    final TriValues<String> triValues = TriValues();
    triValues.first = parts[0];
    triValues.second = parts[1];
    triValues.third = parts[2];
    return triValues;
  }

  static Future<Pair<int>> getTotalPackageCount(ManagedContext context) async {
    final query = Query<Dependency>(context);
    final averageBuildTime = await query.reduce.average((object) =>
    object.buildTime);
    final indexedPackageCount = await query.reduce.count();
    return Pair(indexedPackageCount, averageBuildTime.floor());
  }
}


class TriValues<T>{

  T first,second,third;

}

class Pair<T> {
  Pair(this.first, this.second);

  T first, second;
}