import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
class AppConfiguration extends Configuration{
  AppConfiguration(String configPath) : super.fromFile(File(configPath));
  DatabaseConfiguration database;
}