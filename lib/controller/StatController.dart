import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/utils/DbUtils.dart';

class StatController extends ResourceController {
  StatController(this.context);

  final ManagedContext context;

  @Operation.get()
  Future<Response> getStat() async{
    try{
      final statData = await DbUtils.getTotalPackageCount(context);
        return Response.ok({
          "indexCount": statData.first,
          "avgBT": statData.second
        });
    }
    catch(e){
        logger.log(Level.SEVERE, e.toString());
        return Response.serverError();
    }
  }
}