import 'package:yo_te_pago/business/domain/entities/currency.dart';


class CurrencyDto extends Currency {

  CurrencyDto({
    required super.id,
    required super.name,
    required super.fullName,
    required super.symbol
  });

  factory CurrencyDto.fromJson(Map<String, dynamic> json) {

    return CurrencyDto(
        id: json['id'] == false ? null : json['id'],
        name: json['name'],
        fullName: json['fullName'],
        symbol: json['symbol']
    );
  }

  Currency toModel() {

    return Currency(
        id: id,
        name: name,
        fullName: fullName,
        symbol: symbol
    );
  }

}
