import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';


abstract class IBaseService {

  Future<List<Rate>> getRates({int? id});
  Future<List<Rate>> getAvailableCurrencies();
  Future<Rate> addRate(Rate rate);
  Future<bool> changeRate(Rate rate);
  Future<bool> deleteRate(Rate rate);

  Future<List<Remittance>> getRemittances({int? id});
  Future<Remittance> addRemittance(Remittance remittance);
  Future<bool> editRemittance(Remittance remittance);
  Future<bool> payRemittance(Remittance remittance);
  Future<bool> confirmRemittance(Remittance remittance);
  Future<bool> deleteRemittance(Remittance remittance);

  Future<List<Balance>> getBalances();
  Future<bool> addBalance(Balance balance);

  Future<List<BankAccount>> getBankAccounts();

  Future<List<User>> getDeliveries();
  Future<bool> editUser(String login);
  Future<bool> editPartner(String name);

}