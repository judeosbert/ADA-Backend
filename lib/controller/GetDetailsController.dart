import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:io/io.dart';
import 'package:size_checker/AppConfiguration.dart';
import 'package:size_checker/models/BuildStatus.dart';
import 'package:size_checker/models/Dependency.dart';
import 'package:size_checker/models/FailedDependency.dart';
import 'package:size_checker/models/PackageInfo.dart';
import 'package:size_checker/models/PortData.dart';
import 'package:size_checker/utils/constants.dart';
import 'package:uuid/uuid.dart';
import 'package:worker_manager/worker_manager.dart';

class GetDetailsController extends ResourceController {
  GetDetailsController(this.context);

  final ManagedContext context;

  @Operation.post('packageName')
  Future<Response> getLibrarySize(
      @Bind.path("packageName") String impurePackageName) async {
    try {
      final packageName = cleanPackageName(impurePackageName);
      final Map<String, dynamic> bodyMap = await request.body.decode()??{};
      final String repo = bodyMap["repo"].toString()??"";
      final PackageInfo packageInfo = PackageInfo.from(packageName, repo);

      final Query<Dependency> query = Query<Dependency>(context)
        ..where((dep) => dep.domain).equalTo(packageInfo.domain)
        ..where((dep) => dep.module).equalTo(packageInfo.module)
        ..where((dep) => dep.version).equalTo(packageInfo.version);

      final Dependency dependency = await query.fetchOne();
      if (dependency != null) {
        await _updateLastAccessTime(dependency);
        return Response.ok(dependency);
      }

      //No Dependency in DB ,
      //
      final String token = Uuid().v4();
      logger.log(
          Level.INFO, "Starting background processing and returning token");
      await _scheduleBackgroundJob(
          token, packageInfo.completePackage, packageInfo.repo);
      return Response.ok({"token": token});
    } catch (e) {
      logger.log(Level.SEVERE, e.toString());
      return Response.serverError();
    }
  }

  String cleanPackageName(String packageInput) {
    final keywordsToReplace = [
      "implementation",
      "api",
      "\"",
      "'",
      "compile",
      " "
    ];
    var packageName = packageInput;
    keywordsToReplace.forEach((keyword) {
      packageName = packageName.replaceAll(keyword, "");
    });
    return packageName;
  }

  Future<void> _updateLastAccessTime(Dependency dependency) async {
    final updateLastAccessQuery = Query<Dependency>(context)
      ..values.lastAccess = DateTime.now()
      ..where((dep) => dep.id).equalTo(dependency.id);
    await updateLastAccessQuery.update();
  }

  Future<void> _scheduleBackgroundJob(
      String token, String completePackageName, String repo) async {
    final PortData portData = PortData(completePackageName, token, repo);
    Executor().execute(arg1: portData, fun1: _startProcess);
  }
}

ManagedContext _openDBConnection() {
  final AppConfiguration appConfiguration = AppConfiguration("config.yaml");
  final dataModel = ManagedDataModel.fromCurrentMirrorSystem();
  final store = PostgreSQLPersistentStore.fromConnectionInfo(
      appConfiguration.database.username,
      appConfiguration.database.password,
      appConfiguration.database.host,
      appConfiguration.database.port,
      appConfiguration.database.databaseName, useSSL: Platform.isLinux);
  final context = ManagedContext(dataModel, store);
  return context;
}

Future<void> _insertStatus(
    ManagedContext context, String token, BuildStatusState state) async {

  final buildStatusMessage = BuildStatus.getBuildStatusMessage(state);

  if (state == BuildStatusState.init) {
    final insertQuery = Query<BuildStatus>(context)
      ..values.pingToken = token
      ..values.currentStatus = buildStatusMessage;
    await insertQuery.insert();
    return;
  }
  final updateQuery = Query<BuildStatus>(context)
    ..values.currentStatus = buildStatusMessage
    ..where((BuildStatus status) => status.pingToken)
    .like(token);
  await updateQuery.update();

}

Future<void> _startProcess(PortData portData) async {
  final context = _openDBConnection();

  final Logger logger = Logger("port-logger");
  final File logFile = File("logs/background/${portData.token}.log");
  logFile.createSync(recursive: true);
  logger.onRecord.listen((rec) {
    logFile.writeAsStringSync(
        "${rec.time} | ${rec.level} | ${rec.message} | ${rec.loggerName}\n",
        mode: FileMode.append);
    print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}");
  });
  final buildStartTime = DateTime.now();
  final String token = portData.token;
  await _insertStatus(context, token,BuildStatusState.init);
  final PackageInfo packageInfo = portData.packageInfo;
  logger.log(Level.INFO, "Generating Gradle File");
  final implementationLine = "implementation '${packageInfo.completePackage}'";
  String projectGradleFileContent = "";
  String gradleFileContent = "";
  final FileDirs fileDirs = FileDirs(token);
  final tempDirectory = Directory(fileDirs.tempBaseApplicationPath);
  tempDirectory.createSync(recursive: true);
  final buildLogFile = File("${FileDirs.buildLogPath}${token}.log");
  final buildLogFileSink = buildLogFile.openWrite();


  copyPathSync(FileDirs.baseApplicationDirectory.path, tempDirectory.path);

  //Project Gradle
  final projectGradleHeadFile = File(fileDirs.projectGradleFileHeadPath);
  final projectGradleTailFile = File(fileDirs.projectGradleFileTailPath);
  final projectGradleFile = File(fileDirs.projectGradleFilePath);
  projectGradleFileContent = projectGradleHeadFile.readAsStringSync();
  projectGradleFileContent += "\n";
  projectGradleFileContent += portData.repo;
  projectGradleFileContent += "\n";
  projectGradleFileContent += projectGradleTailFile.readAsStringSync();
  projectGradleFile.writeAsStringSync(projectGradleFileContent);

  logger.log(
      Level.INFO, "Generated Project Gradle File \n $projectGradleFileContent");

  //App Gradle
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
  await _insertStatus(context, token,BuildStatusState.clean);
  final cleanResult = await Process.start("./gradlew", ["clean"],
      workingDirectory: tempDirectory.absolute.path);
  await stdout.addStream(cleanResult.stdout);
  await stdout.addStream(cleanResult.stderr);
  print("Clean process complete");
  await _insertStatus(context, token,BuildStatusState.building);
  print("Starting to assemble release build");
  final releaseResult = await Process.start("./gradlew", ["assembleRelease"],
      workingDirectory: tempDirectory.absolute.path);
  await stdout.addStream(releaseResult.stdout);
  await buildLogFileSink.addStream(releaseResult.stderr);

  Future<void> insertData(int size, {bool isSuccess = false}) async {
    final buildEndTime = DateTime.now();
    final totalBuildTime = buildEndTime.difference(buildStartTime).inSeconds;
    if (isSuccess) {
      final insertSizeQuery = Query<Dependency>(context)
        ..values.domain = packageInfo.domain
        ..values.module = packageInfo.module
        ..values.version = packageInfo.version
        ..values.lastUpdate = DateTime.now()
        ..values.pingToken = token
        ..values.isSuccess = isSuccess
        ..values.sizeInBytes = size
        ..values.lastAccess = DateTime.now()
        ..values.buildTime = totalBuildTime;
      await insertSizeQuery.insert();
    } else {
      final insertSizeQuery = Query<FailedDependency>(context)
        ..values.domain = packageInfo.domain
        ..values.module = packageInfo.module
        ..values.version = packageInfo.version
        ..values.lastUpdate = DateTime.now()
        ..values.pingToken = token
        ..values.isSuccess = isSuccess
        ..values.sizeInBytes = size
        ..values.lastAccess = DateTime.now();

      await insertSizeQuery.insert();
    }
  }

  Future<void> deleteTempProject() async {
    logger.log(Level.INFO, "Deleting ${fileDirs.tempBaseApplicationPath}");
    Directory(fileDirs.tempBaseApplicationPath).deleteSync(recursive: true);
  }

  final releaseArtifact = File(fileDirs.releaseArtifactPath);
  logger.log(Level.INFO, fileDirs.releaseArtifactPath);
  if (!releaseArtifact.existsSync()) {
    await _insertStatus(context, token,BuildStatusState.failed);
    print("Release apk not found after build process");
    await insertData(0);
    await deleteTempProject();
    await buildLogFileSink.flush();
    await buildLogFileSink.close();
    return;
  } else {
    print("Release build generated");
  }

  final releaseArtifactSize = releaseArtifact.lengthSync();
  print("New Generated Artifact size $releaseArtifactSize");
  final diffInSize = releaseArtifactSize - FileDirs.releaseAppSize;
  print("Library Size $diffInSize");
  await _insertStatus(context, token,BuildStatusState.success);
  await insertData(diffInSize, isSuccess: diffInSize > 0);

  logger.log(
      Level.INFO, "Package Size inserted for ${packageInfo.completePackage}");
  await deleteTempProject();
  await buildLogFileSink.flush();
  await buildLogFileSink.close();
  buildLogFile.deleteSync(recursive: true);


}
