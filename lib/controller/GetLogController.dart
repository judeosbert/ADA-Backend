import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/utils/constants.dart';

class GetLogController extends ResourceController{
  GetLogController(this.context);
  ManagedContext context;

  @Operation.get('token')
  Future<Response> getLogForToken(@Bind.path('token') String token) async {

    if(token.isEmpty || token == null){
      return Response.notFound();
    }

    final buildLogFile = File("${FileDirs.buildLogPath}${token}.log");

    if(!buildLogFile.existsSync()){
      return Response.notFound();
    }

    final logContent  = buildLogFile.readAsStringSync();
    return Response.ok(logContent);

  }
}