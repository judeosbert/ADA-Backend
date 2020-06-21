import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:io/io.dart';
import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/Dependency.dart';
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
      final getStatusQuery = Query<Dependency>(context)
        ..where((dep) => dep.pingToken)
            .like(token);
      final dependency = await getStatusQuery.fetchOne();
      if (dependency == null) {
        return Response.noContent();
      }
      return Response.ok(dependency);
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
      return Response.serverError();
    }
  }

}