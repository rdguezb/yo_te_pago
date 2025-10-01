import 'package:yo_te_pago/business/config/helpers/human_formats.dart';

class Balance {

  int currencyId;
  String name;
  String fullName;
  String symbol;
  double debit;
  double credit;
  double balance;
  int partnerId;
  String partnerName;

  Balance({
    required this.currencyId,
    required this.name,
    required this.fullName,
    required this.symbol,
    required this.partnerId,
    required this.partnerName,
    required this.debit,        // este valor es el que paga el remesero de su saldo
    required this.credit,       // este valor es el que le dan al remesero
    this.balance = 0
  });

  factory Balance.fromJson(Map<String, dynamic> json) {

    return Balance(
        currencyId: (json['currency_id'] as int?) ?? 0,
        name: json['name'],
        fullName: json['fullName'],
        symbol: json['symbol'],
        partnerId: (json['partner_id'] as int?) ?? 0,
        partnerName: json['partner_name'],
        debit: json['debit'],
        credit: json['credit'],
        balance: json['balance']
    );
  }

  double get total => debit - credit;

  String get currency => '[$name] $fullName';

  String totalToString() => HumanFormats.toAmount(total, symbol);

  String balanceToString(String sign) {
    if (sign == 'D') {
      return 'D: ${HumanFormats.toAmount(debit, symbol)}';
    }

    return 'C: ${HumanFormats.toAmount(credit, symbol)}';
  }

}
