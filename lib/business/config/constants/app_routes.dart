abstract class AppRoutes {

  // names

  static const home = 'home';
  static const register = 'register';
  static const remittanceEdit = 'remittance-edit';
  static const remittanceCreate = 'remittance-create';
  static const rate = 'rate';
  static const balance = 'balance';
  static const account = 'account';
  static const profile = 'profile';

  // path

  static const loadingUrl = '/loading';
  static const homeUrl = '/home/:page';
  static const registerUrl = '/register';
  static const remittanceEditUrl = '/remittance/edit/:id';
  static const remittanceCreateUrl = '/remittance/create';
  static const rateUrl = '/rate/create';
  static const balanceUrl = '/balance/create';
  static const accountUrl = '/account/link';
  static const profileUrl = '/setting/profile';
  static const passwordUrl = '/setting/password';
  static const usersUrl = '/setting/users';
  static const currenciesUrl = '/setting/currencies';
  static const banksUrl = '/setting/banks';
  static const bankAccountsUrl = '/setting/bank-accounts';
  static const settingsUrl = '/setting/settings';
  static const appUpdateUrl = '/setting/app-update';

}