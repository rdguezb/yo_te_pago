import 'package:yo_te_pago/business/domain/entities/currency.dart';


class CurrencyDto extends Currency {

  CurrencyDto({
    required super.id,
    required super.name,
    required super.fullName,
    required super.symbol,
    super.rate,
    super.isReference,
    super.isActive
  });

  factory CurrencyDto.fromJson(Map<String, dynamic> json) {

    return CurrencyDto(
        id: (json['id'] as int?) ?? 0,
        name: json['name'],
        fullName: json['fullName'],
        symbol: json['symbol'],
        rate: (json['rate'] as double?) ?? 0,
        isReference: (json['is_company_currency'] as bool),
        isActive: (json['is_allow'] as bool)
    );
  }

  Currency toModel() {

    return Currency(
        id: id,
        name: name,
        fullName: fullName,
        symbol: symbol,
        rate: rate,
        isReference: isReference,
        isActive: isActive
    );
  }

}
