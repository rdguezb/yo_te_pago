import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/company.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/entities/role.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';


abstract class IBaseService {

// Rates

  Future<List<Rate>> getRates({int? id});
  Future<Rate> addRate(Rate rate);
  Future<bool> changeRate(Rate rate);
  Future<bool> deleteRate(int id);

// Currencies

  Future<List<Currency>> getAllowCurrencies();
  Future<List<Currency>> getCurrencies({int limit = 20, int offset = 0});
  Future<bool> toggleCurrencyActive(int currencyId);
  Future<bool> updateCurrencyRate(int currencyId, double rate);

// Remittances

  Future<List<Remittance>> getRemittances({int? id});
  Future<Remittance> addRemittance(Remittance remittance);
  Future<bool> editRemittance(Remittance remittance);
  Future<bool> payRemittance(int id);
  Future<bool> confirmRemittance(int id);
  Future<bool> deleteRemittance(int id);

// Balances

  Future<List<Balance>> getBalances();
  Future<bool> updateBalance(int currencyId, int partnerId, double amount, String type);

  // Accounts

  Future<List<Account>> getAccounts();
  Future<bool> deleteAccount(int partnerId, int accountId);
  Future<bool> linkAccount(int partnerId, int accountId);

// Bank Accounts

  Future<List<BankAccount>> getBankAccounts();
  Future<BankAccount> addBankAccount(BankAccount bankAccount);
  Future<bool> deleteBankAccount(int bankAccountId);
  Future<bool> updateBankAccount(BankAccount bankAccount);

// Banks

  Future<List<Bank>> getBanks();
  Future<Bank> addBank(Bank bank);
  Future<bool> updateBank(Bank bank);

// Users & Role

  Future<List<User>> getDeliveries();
  Future<List<User>> getUsers();
  Future<bool> editUser(User user);
  Future<User> createUser(Map<String, dynamic> user);
  Future<bool> adminSetUserPassword(int userId, String newPassword);
  Future<bool> userChangeOwnPassword({required String oldPassword, required String newPassword});
  Future<bool> deleteUser(int userId);
  Future<List<Role>> getRoles();

// Settings

  Future<Map<String, dynamic>> getParameters();
  Future<bool> updateParameters(Company company);
}