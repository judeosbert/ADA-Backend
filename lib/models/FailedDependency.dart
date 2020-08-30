import 'package:aqueduct/aqueduct.dart';

class FailedDependency extends ManagedObject<_FailedDependency> implements _FailedDependency{
  Map toJson() => {
    "data": {
      "domain": domain,
      "module": module,
      "version": version,
      "size": sizeInBytes,
      "lastUpdate": lastUpdate,
    }
  };

}

class _FailedDependency{
  @primaryKey
  int id;

  String domain;

  String module;

  String version;

  int sizeInBytes;

  String pingToken;

  DateTime lastUpdate;

  DateTime lastAccess;

  bool isSuccess;
}