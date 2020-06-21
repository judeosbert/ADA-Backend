class DbUtils{
  static TriValues<String> getPackageDetailsFrom(String completePackage){
    if(completePackage == null || completePackage.isEmpty){
      return TriValues();
    }

    final parts = completePackage.split(":");
    final TriValues<String> triValues = TriValues();
    triValues.first = parts[0];
    triValues.second = parts[1];
    triValues.third = parts[2];
    return triValues;

  }
}

class TriValues<T>{

  T first,second,third;

}