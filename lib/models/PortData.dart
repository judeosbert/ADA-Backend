import 'dart:convert';

import 'PackageInfo.dart';


class PortData{
  PortData(this.completePackage,this.token);

  PortData.fromJson(String first) {
      print("Converting object $first");
     final Map<String,dynamic> map = jsonDecode(first) as Map<String,dynamic>;
     completePackage = map["completePackage"].toString();
     token = map["token"].toString();
    }

  String completePackage;
  String token;

  PackageInfo get packageInfo => PackageInfo.from(completePackage);


  @override
  String toString() =>  jsonEncode(toJson());

  Map toJson() =>{
    "completePackage":completePackage,
    "token":token
  };



}