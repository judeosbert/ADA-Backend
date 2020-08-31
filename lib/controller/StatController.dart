import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/utils/DbUtils.dart';

class StatController extends ResourceController {
  StatController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getStat() async{
    try{
        final count = await DbUtils.getTotalPackageCount(context);
        return Response.ok({
          "indexCount":count
        });
    }
    catch(e){
        logger.log(Level.SEVERE, e.toString());
        return Response.serverError();
    }
  }
}