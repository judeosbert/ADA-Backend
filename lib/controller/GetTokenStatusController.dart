import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/BuildStatus.dart';
import 'package:size_checker/models/Dependency.dart';
import 'package:size_checker/models/FailedDependency.dart';

class GetTokenStatusController extends ResourceController {
  GetTokenStatusController(this.context);

  final ManagedContext context;

  @Operation.get('token')
  Future<Response> getTokenStatus(@Bind.path("token") String token) async {
    try {
      final status = await _getBuildStateStatus(token);
      final buildState = BuildStatus.getStateFromMessage(status.currentStatus);

      switch(buildState){
        case BuildStatusState.success:
          try {
            final dep = await getStatusFromSuccessDB(token);
            return Response.ok(dep);
          } catch (e) {
            logger.log(Level.FINE, "Token not in Success DB");
            Response.serverError();
          }
          break;
        case BuildStatusState.failed:
          try {
            final failedDep = await getStatusFromFailedDB(token);
            final dep =  Dependency.fromFailedDependency(failedDep);
            return Response.ok(dep);
          } catch (e) {
            logger.log(Level.FINE, "Token not in Failed DB");
          }
          break;
        default:
          return Response.ok({"status":status.currentStatus});
          break;
      }
    } catch (e) {
      logger.log(Level.FINE, "Package Not yet inserted");
      return Response.noContent();
    }
  }

  Future<BuildStatus> _getBuildStateStatus(String pingToken) async{
    final getStatusQuery = Query<BuildStatus>(context)
        ..where((status) => status.pingToken)
        .like(pingToken);
    final buildStatus = getStatusQuery.fetchOne();
    return buildStatus;

  }

  Future<Dependency> getStatusFromSuccessDB(String pingToken) async {
    try {
      final getStatusQuery = Query<Dependency>(context)
        ..where((dep) => dep.pingToken).like(pingToken);
      final dependency = await getStatusQuery.fetchOne();
      if (dependency == null) {
        return Future.error("not found-successdb");
      }
      return dependency;
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
      return Future.error("not found-successdb");
    }
  }

  Future<FailedDependency> getStatusFromFailedDB(String pingToken) async {
    try {
      final getStatusQuery = Query<FailedDependency>(context)
        ..where((dep) => dep.pingToken).like(pingToken);
      final dependency = await getStatusQuery.fetchOne();
      if (dependency == null) {
        return Future.error("not found-faileddb");
      }
      return dependency;
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
      return Future.error("not found-faileddb");
    }
  }
}

class NotFoundException extends FileSystemException {}
