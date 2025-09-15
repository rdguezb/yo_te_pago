import 'package:yo_te_pago/business/domain/entities/balance.dart';


class BalanceDto extends Balance {

  BalanceDto({
    required super.currencyId,
    required super.name,
    required super.fullName,
    required super.symbol,
    required super.partnerId,
    required super.partnerName,
    required super.debit,
    required super.credit,
    required super.balance
  });

  factory BalanceDto.fromJson(Map<String, dynamic> json) {

    return BalanceDto(
        currencyId: (json['currency_id'] as int?) ?? 0,
        name: json['name'],
        fullName: json['fullName'],
        symbol: json['symbol'],
        partnerId: (json['partner_id'] as int?) ?? 0,
        partnerName: json['partner_name'],
        debit: json['debit']?.toDouble(),
        credit: json['credit']?.toDouble(),
        balance: json['balance']?.toDouble()
    );
  }

  Balance toModel() {

    return Balance(
      currencyId: currencyId,
      name: name,
      fullName: fullName,
      symbol: symbol,
      partnerId: partnerId,
      partnerName: partnerName,
      debit: debit,
      credit: credit,
      balance: balance
    );
  }

}
