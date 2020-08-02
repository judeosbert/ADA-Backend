import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/Dependency.dart';

class RecentSearchesController extends ResourceController {
  RecentSearchesController(this._context);
  final ManagedContext _context;

  @Operation.get()
  Future<Response> getRecentSearches() async{
    try{
      final query = Query<Dependency>(_context)
        ..sortBy((dep) => dep.lastAccess, QuerySortOrder.descending);
      query.fetchLimit = 5;
      final recentDependencies = await query.fetch();
      return Response.ok(recentDependencies);
    } catch(e){
      return Response.serverError();
    }

  }
}