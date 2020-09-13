import 'package:aqueduct/aqueduct.dart';

class BuildStatus extends ManagedObject<_BuildStatus> implements _BuildStatus{

  static String getBuildStatusMessage(BuildStatusState state) {
    switch (state) {
      case BuildStatusState.init:
        return "Preparing to start job";
        break;
      case BuildStatusState.clean:
        return "Cleaning the enviroment";
        break;
      case BuildStatusState.building:
        return "Building for a better tomorrrow";
        break;
      case BuildStatusState.success:
        return "Mission Successful";
        break;
      case BuildStatusState.failed:
        return "Mission Failed. Should look at the logs";
        break;
      default:
        return "I have no idea what to do";
        break;
    }
  }

  static BuildStatusState getStateFromMessage(String message){
    switch(message){
      case  "Preparing to start job":
        return BuildStatusState.init;
        break;
      case "Cleaning the enviroment":
        return BuildStatusState.clean;
        break;
      case "Building for a better tomorrrow" :
        return BuildStatusState.building;
        break;
      case "Mission Successful" :
        return BuildStatusState.success ;
        break;
      case "Mission Failed. Should look at the logs":
        return BuildStatusState.failed;
        break;
      default:
        return BuildStatusState.unknown;
        break;
    }
  }
}

class _BuildStatus{
  @Column(primaryKey: true)
  String pingToken;
  @Column()
  String currentStatus;
}

enum BuildStatusState{
  init,clean,building,success,failed,unknown
}