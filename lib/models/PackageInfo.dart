import 'package:size_checker/utils/DbUtils.dart';

class PackageInfo{

  PackageInfo.from(String completePackageName,String repo){
    final TriValues<String> triValues = DbUtils.getPackageDetailsFrom(completePackageName);
    domain = triValues.first;
    module = triValues.second;
    version = triValues.third;
    this.repo = repo;
  }

  Map toJson() =>
      {
        "domin":domain,
        "module":module,
        "version":version
      };



  String get completePackage=>"$domain:$module:$version";
  String domain;
  String module;
  String version;
  String repo;

}