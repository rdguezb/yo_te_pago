import 'package:isar/isar.dart';


part 'app_data_poco.g.dart';

@collection
class AppDataPoco {

  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String keyName;
  String valueStr;
  String valueType;

  AppDataPoco({
    this.id = Isar.autoIncrement,
    required this.keyName,
    required this.valueStr,
    required this.valueType
  });

}
