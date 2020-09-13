import 'package:aqueduct/aqueduct.dart';
import 'package:size_checker/models/Dependency.dart';

class SearchPackageController extends ResourceController {
  SearchPackageController(this.context);

  ManagedContext context;

  @Operation.get()
  Future<Response> getSearchResults(@Bind.query("query") String query) async {
    try {
      logger.log(Level.INFO, "Searching for $query");
      final getResultsQueryForDomain = Query<Dependency>(context)
        ..where((dep) => dep.domain).like("%$query%")
        ..sortBy((dep) => dep.lastAccess, QuerySortOrder.descending);
      getResultsQueryForDomain.fetchLimit = 5;
      final domainResults = await getResultsQueryForDomain.fetch();
      logger.log(Level.INFO, "Domain Results $domainResults");

      final getResultsQueryForModule = Query<Dependency>(context)
        ..where((dep) => dep.module).like("%$query%")
        ..sortBy((dep) => dep.lastAccess, QuerySortOrder.descending);
      getResultsQueryForModule.fetchLimit = 5;
      final moduleResults = await getResultsQueryForModule.fetch();
      logger.log(Level.INFO, "Module Results $moduleResults");
      final results = domainResults;
      results.addAll(moduleResults);
      results.sort((dep1, dep2) {
        return dep1.lastAccess.compareTo(dep2.lastAccess);
      });

      logger.log(Level.INFO, "Results $results");
      final packageResults = results.take(5).toList(growable: false).map((dep) {
        return "${dep.domain}:${dep.module}:${dep.version}";
      }).toList(growable: false);

      return Response.ok(packageResults);
    } catch (e) {
      logger.log(Level.SEVERE, e);
      return Response.serverError();
    }
  }
}
