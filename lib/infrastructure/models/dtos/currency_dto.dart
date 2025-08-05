import 'package:yo_te_pago/business/domain/entities/currency.dart';


class CurrencyDto extends Currency {

  CurrencyDto({
    required super.id,
    required super.name,
    required super.fullName,
    required super.symbol,
    required super.rate
  });

  factory CurrencyDto.fromJson(Map<String, dynamic> json) {

    return CurrencyDto(
        id: json['id'],
        fullName: json['fullName'],
        name: json['name'],
        symbol: json['symbol'],
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0
    );
  }

  Currency toModel() {

    return Currency(
      id: id,
      name: name,
      fullName: fullName,
      symbol: symbol,
      rate: rate
    );
  }

}
