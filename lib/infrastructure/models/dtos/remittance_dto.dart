import 'package:yo_te_pago/business/domain/entities/remittance.dart';


class RemittanceDto extends Remittance {

  RemittanceDto({
    required super.id,
    required super.customer,
    required super.amount,
    required super.createdAt,
    required super.state,
    required super.currencyId,
    required super.currencyName,
    required super.currencySymbol,
    required super.rate,
    required super.bankAccountId,
    required super.bankAccountName,
    super.bankName,
    super.code
  });

  factory RemittanceDto.fromJson(Map<String, dynamic> json) {


    return RemittanceDto(
        id: (json['id'] as int?) ?? 0,
        customer: (json['name'] as String?) ?? '',
        code: (json['code'] as String?) ?? '',
        createdAt: DateTime.parse(json['date']),
        amount: (json['amount']?.toDouble()) ?? 0.0,
        state: (json['state'] as String?) ?? 'waiting',
        currencyId: (json['payment_currency_id'] as int?) ?? 0,
        currencyName: (json['currency_name'] as String?) ?? 'N/A',
        currencySymbol: (json['currency_symbol'] as String?) ?? '',
        rate: (json['rate']?.toDouble()) ?? 0.0,
        bankAccountId: (json['bank_id'] as int?) ?? 0,
        bankAccountName: (json['acc_number'] as String?) ?? 'N/A',
        bankName: json['bank_name'] as String?
    );
  }

  Remittance toModel() {

    return Remittance(
      id: id,
      customer: customer,
      code: code,
      createdAt: createdAt,
      amount: amount,
      state: state,
      currencyId: currencyId,
      currencyName: currencyName,
      currencySymbol: currencySymbol,
      rate: rate,
      bankAccountId: bankAccountId,
      bankAccountName: bankAccountName,
      bankName: bankName
    );
  }

}