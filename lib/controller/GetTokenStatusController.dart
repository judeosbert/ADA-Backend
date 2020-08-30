import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:io/io.dart';
import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/Dependency.dart';
import 'package:size_checker/models/FailedDependency.dart';
import 'package:size_checker/models/PackageInfo.dart';
import 'package:size_checker/models/PortData.dart';
import 'package:size_checker/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:pedantic/pedantic.dart';
import 'package:worker_manager/worker_manager.dart';

import '../channel.dart';

class GetTokenStatusController extends ResourceController {
  GetTokenStatusController(this.context);

  final ManagedContext context;

  @Operation.get('token')
  Future<Response> getTokenStatus(@Bind.path("token") String token) async {
    try {
      final dep = await getStatus(token);
      return Response.ok(dep);
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
      return Response.noContent();
    }
  }

  Future<Dependency> getStatus(String pingToken) async {
    try {
      final response = await getStatusFromSuccessDB(pingToken);
      return response;
    } catch (e) {
      logger.log(Level.FINE, "Token not in Success DB");
    }
    try {
      final response = await getStatusFromFailedDB(pingToken);
      return Dependency.fromFailedDependency(response);
    } catch (e) {
      logger.log(Level.FINE, "Token not in Failed DB");
    }
    throw NotFoundException();
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
