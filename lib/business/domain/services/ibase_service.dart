import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';


abstract class IBaseService {

  Future<List<Rate>> getRates({int? id});
  Future<List<Currency>> getAvailableCurrencies();
  Future<Rate> addRate(Rate rate);
  Future<bool> changeRate(Rate rate);
  Future<bool> deleteRate(int id);

  Future<List<Remittance>> getRemittances({int? id});
  Future<Remittance> addRemittance(Remittance remittance);
  Future<bool> editRemittance(Remittance remittance);
  Future<bool> payRemittance(Remittance remittance);
  Future<bool> confirmRemittance(Remittance remittance);
  Future<bool> deleteRemittance(int id);

  Future<List<Balance>> getBalances();
  Future<bool> updateBalance(int currencyId, int partnerId, double amount, String type);

  Future<List<Account>> getAccounts();
  Future<bool> deleteAccount(Account account);
  Future<bool> linkAccount(Account account);
  Future<List<BankAccount>> getBankAccounts();


  Future<List<User>> getDeliveries();
  Future<bool> editUser(String login);
  Future<bool> editPartner(String name);

}