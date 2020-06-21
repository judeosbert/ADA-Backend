import 'package:aqueduct/aqueduct.dart';

class Dependency extends ManagedObject<_Dependency> implements _Dependency {
  Map toJson() => {
        "data": {
          "domain": domain,
          "module": module,
          "version": version,
          "size": sizeInBytes,
          "lastUpdate": lastUpdate
        }
      };
}

class _Dependency {
  @primaryKey
  int id;

  String domain;

  String module;

  String version;

  int sizeInBytes;

  String pingToken;

  DateTime lastUpdate;

  bool isSuccess;
}
