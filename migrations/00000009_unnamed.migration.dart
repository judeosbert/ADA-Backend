import 'dart:async';

import 'package:aqueduct/aqueduct.dart';

class Migration9 extends Migration {
  @override
  Future upgrade() async {
    database.addColumn(
        "_Dependency",
        SchemaColumn("buildTime", ManagedPropertyType.integer,
            isPrimaryKey: false,
            autoincrement: false,
            isIndexed: false,
            isNullable: false,
            isUnique: false),
        unencodedInitialValue: "-1");
  }

  @override
  Future downgrade() async {}

  @override
  Future seed() async {}
}
