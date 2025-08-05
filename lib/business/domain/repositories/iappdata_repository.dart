import 'package:yo_te_pago/business/domain/entities/app_data.dart';
import 'package:yo_te_pago/business/domain/repositories/ibase_repository.dart';


abstract class IAppDataRepository extends IBaseRepository<AppData> {

  Future<AppData?> getByKey(String key);
  Future<bool> hasApiKey();

}