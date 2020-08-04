import 'dart:io';
class FileDirs {

  FileDirs(String newPath){
    tempBaseApplicationPath ="$demoAppPath$newPath/";
    releaseArtifactPath = tempBaseApplicationPath+"app/build/outputs/apk/release/app-release.apk";
    gradleFilePath = tempBaseApplicationPath+"app/build.gradle";
    gradleFileHeadPath = tempBaseApplicationPath+"app/gradle_build_head";
    gradleFileTailPath = tempBaseApplicationPath+"app/gradle_build_tail";
    projectGradleFilePath = tempBaseApplicationPath+"build.gradle";
    projectGradleFileHeadPath = tempBaseApplicationPath+"gradle_build_head";
    projectGradleFileTailPath = tempBaseApplicationPath+"gradle_build_tail";

  }

  static const int releaseAppSize = 1440979;
  static final  String _currentPath = Directory.current.path;
  static final String baseApplicationPath = demoAppPath+"MyApplication/";
  static final Directory baseApplicationDirectory = Directory(baseApplicationPath);
  static final String demoAppPath = _currentPath+"/lib/base_app/";


  String tempBaseApplicationPath = "";
  String releaseArtifactPath = "";
  String gradleFilePath = "";
  String gradleFileHeadPath = "";
  String gradleFileTailPath = "";
  String projectGradleFilePath = "";
  String projectGradleFileHeadPath = "";
  String projectGradleFileTailPath = "";

}