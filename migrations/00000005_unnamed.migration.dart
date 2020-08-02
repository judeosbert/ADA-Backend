import 'dart:async';
import 'package:aqueduct/aqueduct.dart';   

class Migration5 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Dependency", SchemaColumn("lastAccess", ManagedPropertyType.datetime, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: false, isUnique: false),unencodedInitialValue: "'2020-08-02 14:15:23.826274'");
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    