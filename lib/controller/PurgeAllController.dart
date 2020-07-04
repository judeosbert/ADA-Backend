import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/Dependency.dart';

class PurgeAllController extends ResourceController {
  PurgeAllController(this.context);

  ManagedContext context;

  @Operation.delete()
  Future<Response> purgeAll() async {
    try {
      final deleteQuery = Query<Dependency>(context)
        ..where((dep) => dep.id).greaterThanEqualTo(0);
      await deleteQuery.delete();
      return Response.ok("success");
    } catch(e){
      logger.log(Level.SEVERE, e);
      return Response.serverError();
    }
  }
}