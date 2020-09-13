import 'dart:async';

import 'package:aqueduct/aqueduct.dart';

class Migration8 extends Migration {
  @override
  Future upgrade() async {
    database.createTable(SchemaTable("_BuildStatus", [
      SchemaColumn("pingToken", ManagedPropertyType.string,
          isPrimaryKey: true,
          autoincrement: false,
          isIndexed: false,
          isNullable: false,
          isUnique: false),
      SchemaColumn("currentStatus", ManagedPropertyType.string,
          isPrimaryKey: false,
          autoincrement: false,
          isIndexed: false,
          isNullable: false,
          isUnique: false)
    ]));
  }

  @override
  Future downgrade() async {}

  @override
  Future seed() async {}
}
