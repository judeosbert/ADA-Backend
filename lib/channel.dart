import 'package:size_checker/controller/GetDetailsController.dart';
import 'package:worker_manager/worker_manager.dart';

import 'controller/GetTokenStatusController.dart';
import 'size_checker.dart';

/// This type initializes an application.
///
/// Override methods in this class to set up routes and initialize services like
/// database connections. See http://aqueduct.io/docs/http/channel/.
class SizeCheckerChannel extends ApplicationChannel {
  /// Initialize services in this method.
  ///
  /// Implement this method to initialize services, read values from [options]
  /// and any other initialization required before constructing [entryPoint].
  ///
  /// This method is invoked prior to [entryPoint] being accessed.
  ///

  ManagedContext context;

  @override
  Future prepare() async {
    final File file = File("app-logs/app/app_logs.log");
    if (!file.existsSync())
      file.createSync(recursive: true);
    logger.onRecord.listen((rec) {
      file.writeAsStringSync(
          "${rec.time} | ${rec.level} | ${rec.message} | ${rec.loggerName}\n",
          mode: FileMode.append);
      print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}");
    });
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final store = PostgreSQLPersistentStore.fromConnectionInfo(
        "rider",
        "rider_mamoth1",
        "localhost",
        5432,
        "rider");
    context = ManagedContext(dataModel, store);
    await Executor().warmUp(log: true);
  }

  /// Construct the request channel.dart
  ///
  /// Return an instance of some [Controller] that will be the initial receiver
  /// of all [Request]s.
  ///
  /// This method is invoked after [prepare].
  @override
  Controller get entryPoint {
    final router = Router();

    // Prefer to use `link` instead of `linkFunction`.
    // See: https://aqueduct.io/docs/http/request_controller/
    router
        .route("/details/:packageName")
        .link(() => GetDetailsController(context));
    router
        .route("/status/:token")
        .link(() => GetTokenStatusController(context));

    return router;
  }
}
