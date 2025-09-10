abstract class OdooEndpoints {

  static const String authenticate = '/web/session/authenticate';
  static const String logout = '/web/session/logout';
  static const String callKw = '/web/dataset/call_kw';

  static const String getBalances = '/api/v1/balance/total';
  static const String getRates = '/api/v1/rates/get';
  static const String getCurrencies = '/api/v1/currency/get';
  static const String getRemittances = '/api/v1/remittance/get';
  static const String getBankAccount = '/api/v1/accounts/get';

}