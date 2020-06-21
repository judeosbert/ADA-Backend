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
import 'package:worker_manager/worker_manager.dart';

class GetDetailsController extends ResourceController {
  GetDetailsController(this.context);

  final ManagedContext context;

  @Operation.get('packageName')
  Future<Response> getLibrarySize(
      @Bind.path("packageName") String packageName) async {
    try {
      final PackageInfo packageInfo = PackageInfo.from(packageName);

      final Query<Dependency> query = Query<Dependency>(context)
        ..where((dep) => dep.domain).equalTo(packageInfo.domain)
        ..where((dep) => dep.module).equalTo(packageInfo.module)
        ..where((dep) => dep.version).equalTo(packageInfo.version);

      final Dependency dependency = await query.fetchOne();
      if (dependency != null) {
        return Response.ok(dependency);
      }

      //No Dependency in DB ,
      //
      final String token = Uuid().v4();
      logger.log(
          Level.INFO, "Starting background processing and returning token");
      await _scheduleBackgroundJob(token, packageInfo.completePackage);
      return Response.ok({"token": token});
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
      return Response.serverError();
    }
  }

  Future<void> _scheduleBackgroundJob(
      String token, String completePackageName) async {
    final PortData portData = PortData(completePackageName, token);
    Executor().execute(arg1: portData, fun1: _startProcess);
  }
}

Future<void> _startProcess(PortData portData) async {
  final Logger logger = Logger("port-logger");
  final File logFile = File("logs/background/${portData.token}.log");
  logFile.createSync(recursive: true);
  logger.onRecord.listen((rec) {
    logFile.writeAsStringSync(
        "${rec.time} | ${rec.level} | ${rec.message} | ${rec.loggerName}\n",
        mode: FileMode.append);
    print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}");
  });
  final String token = portData.token;
  final PackageInfo packageInfo = portData.packageInfo;
  logger.log(Level.INFO, "Generating Gradle File");
  final implementationLine = "implementation '${packageInfo.completePackage}'";
  String gradleFileContent = "";
  final FileDirs fileDirs = FileDirs(token);
  final tempDirectory = Directory(fileDirs.tempBaseApplicationPath);
  tempDirectory.createSync(recursive: true);

  copyPathSync(FileDirs.baseApplicationDirectory.path, tempDirectory.path);
  final gradleHeadFile = File(fileDirs.gradleFileHeadPath);
  final gradleTailFile = File(fileDirs.gradleFileTailPath);
  final gradleFile = File(fileDirs.gradleFilePath);
  gradleFileContent = gradleHeadFile.readAsStringSync();
  gradleFileContent += "\n";
  gradleFileContent += implementationLine;
  gradleFileContent += "\n";
  gradleFileContent += gradleTailFile.readAsStringSync();

  logger.log(Level.INFO, "Generated Gradle File \n $gradleFileContent");

  gradleFile.writeAsStringSync(gradleFileContent);
  print("Changing directory to ${fileDirs.tempBaseApplicationPath}");

  logger.log(Level.INFO, "Starting build process.");
  logger.log(Level.INFO, "Starting cleaning process");
  final cleanResult = await Process.start("./gradlew", ["clean"],
      workingDirectory: tempDirectory.absolute.path);
  await stdout.addStream(cleanResult.stdout);
  await stdout.addStream(cleanResult.stderr);
  print("Clean process complete");

  print("Starting to assemble release build");
  final releaseResult = await Process.start("./gradlew", ["assembleRelease"],
      workingDirectory: tempDirectory.absolute.path);
  await stdout.addStream(releaseResult.stdout);
  await stdout.addStream(releaseResult.stderr);

  Future<void> insertData(int size, {bool isSuccess = false}) async {
    final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
    final store = PostgreSQLPersistentStore.fromConnectionInfo(
        "dart_app", "dart", "localhost", 5432, "dependency_database");
    final context = ManagedContext(dataModel, store);

    final insertSizeQuery = Query<Dependency>(context)
      ..values.domain = packageInfo.domain
      ..values.module = packageInfo.module
      ..values.version = packageInfo.version
      ..values.lastUpdate = DateTime.now()
      ..values.pingToken = token
      ..values.isSuccess = isSuccess
      ..values.sizeInBytes = size;

    await insertSizeQuery.insert();
  }

  Future<void> deleteTempProject() async {
    logger.log(Level.INFO, "Deleting ${fileDirs.tempBaseApplicationPath}");
    Directory(fileDirs.tempBaseApplicationPath).deleteSync(recursive: true);
  }

  final releaseArtifact = File(fileDirs.releaseArtifactPath);
  logger.log(Level.INFO, fileDirs.releaseArtifactPath);
  if (!releaseArtifact.existsSync()) {
    print("Release apk not found after build process");
    await insertData(0);
    await deleteTempProject();
    return;
  } else {
    print("Release build generated");
  }

  final releaseArtifactSize = releaseArtifact.lengthSync();
  print("New Generated Artifact size $releaseArtifactSize");
  final diffInSize = releaseArtifactSize - FileDirs.releaseAppSize;
  print("Library Size $diffInSize");
  await insertData(diffInSize, isSuccess: true);
  logger.log(
      Level.INFO, "Package Size inserted for ${packageInfo.completePackage}");
  await deleteTempProject();
}
