class AppData {

  int? id;
  final String keyName;
  final String valueStr;
  final String valueType;

  AppData({
    required this.keyName,
    required this.valueStr,
    required this.valueType,
    this.id
  });

  AppData copyWith({
    int? id,
    String? keyName,
    String? valueStr,
    String? valueType
  }) {
    return AppData(
        id: id ?? this.id,
        keyName: keyName ?? this.keyName,
        valueStr: valueStr ?? this.valueStr,
        valueType: valueType ?? this.valueType
    );
  }

}