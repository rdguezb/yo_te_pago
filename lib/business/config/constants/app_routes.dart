abstract class AppRoutes {

  // names

  static const home = 'home';
  static const register = 'register';
  static const loading = 'loading';

  static const dashboard = 'dashboard';
  static const remittance = 'remittance-add';
  static const balance = 'balance-update';
  static const rate = 'rate-add';
  static const account = 'account-link';

  static const profile = 'setting-profile';
  static const settings = 'setting-settings';
  static const banks = 'setting-banks';
  static const bankAccount = 'setting-bank-accounts';
  static const currency = 'setting-currencies';
  static const banksCreate = 'banks-form';
  static const bankAccountCreate = 'bank-accounts-form';
  static const users = 'setting-users';
  static const usersCreate = 'users-form';

  static const password = 'setting-password';
  static const appUpdate = 'setting-app-update';

  // path

  static const loadingUrl = '/loading';
  static const registerUrl = '/register';
  static const homeUrl = '/home/:page';
  static const dashboardUrl = '/';

  static const remittanceUrl = '/remittance';

  static const balanceUrl = '/balance/create';
  static const rateUrl = '/rate/create';
  static const accountUrl = '/account/link';

  static const profileUrl = '/setting/profile';
  static const settingsUrl = '/setting/settings';
  static const banksUrl = '/setting/banks';
  static const bankCreateUrl = '/banks/create';
  static const bankAccountsUrl = '/setting/bank-accounts';
  static const bankAccountCreateUrl = '/bank-accounts/create';

  static const passwordUrl = '/setting/password';
  static const usersUrl = '/setting/users';
  static const currenciesUrl = '/setting/currencies';
  static const appUpdateUrl = '/setting/app-update';

}