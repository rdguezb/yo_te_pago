class AppDataPoco {

  @override
  int? id;
  String keyName;
  String valueStr;
  String valueType;

  AppDataPoco({
    this.id,
    required this.keyName,
    required this.valueStr,
    required this.valueType
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'keyName': keyName,
      'valueStr': valueStr,
      'valueType': valueType
    };
  }

  factory AppDataPoco.fromMap(Map<String, dynamic> map) {
    return AppDataPoco(
      id: map['id'] as int,
      keyName: map['keyName'] as String,
      valueStr: map['valueStr'] as String,
      valueType: map['valueType'] as String,
    );
  }

}
