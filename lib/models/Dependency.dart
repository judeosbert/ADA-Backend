import 'package:aqueduct/aqueduct.dart';

import 'FailedDependency.dart';

class Dependency extends ManagedObject<_Dependency> implements _Dependency {
  Map toJson() => {
        "data": {
          "domain": domain,
          "module": module,
          "version": version,
          "size": sizeInBytes,
          "lastUpdate": lastUpdate,
        }
      };

  static Dependency fromFailedDependency(FailedDependency dependency){
    final dep = Dependency();
    dep.pingToken = dependency.pingToken;
    dep.isSuccess = dependency.isSuccess;
    dep.sizeInBytes = dependency.sizeInBytes;
    dep.lastAccess = dependency.lastAccess;
    dep.lastUpdate = dependency.lastUpdate;
    dep.id = dependency.id;
    dep.version = dependency.version;
    dep.domain = dependency.domain;
    dep.module = dependency.module;
    return dep;

  }

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

  DateTime lastAccess;

  bool isSuccess;
}
