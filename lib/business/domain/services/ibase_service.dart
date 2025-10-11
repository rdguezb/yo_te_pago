import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/company.dart';
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
  Future<bool> payRemittance(int id);
  Future<bool> confirmRemittance(int id);
  Future<bool> deleteRemittance(int id);

  Future<List<Balance>> getBalances();
  Future<bool> updateBalance(int currencyId, int partnerId, double amount, String type);

  Future<List<Account>> getAccounts();
  Future<bool> deleteAccount(int partnerId, int accountId);
  Future<bool> linkAccount(int partnerId, int accountId);
  Future<List<BankAccount>> getBankAccounts();
  Future<List<Bank>> getBanks();
  Future<Bank> addBank(Bank bank);
  Future<bool> updateBank(Bank bank);


  Future<List<User>> getDeliveries();
  Future<List<User>> getUsers();
  Future<bool> editUser(User user);

  Future<Map<String, dynamic>> getParameters();
  Future<bool> updateParameters(Company company);
}