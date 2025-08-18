import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';


abstract class IBaseService {

  Future<List<Currency>> getCurrencies();
  Future<List<Balance>> getBalances();
  Future<List<BankAccount>> getBankAccounts();

  Future<Remittance> addRemittance(Remittance remittance);
  Future<List<Remittance>> getRemittances({int? id});
  Future<bool> editRemittance(Remittance remittance);
  Future<bool> payRemittance(Remittance remittance);
  Future<bool> deleteRemittance(Remittance remittance);

  Future<bool> editUser(String login);
  Future<bool> editPartner(String name);

}