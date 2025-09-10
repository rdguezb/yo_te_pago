import 'package:yo_te_pago/business/domain/entities/rate.dart';


class RateDto extends Rate {

  RateDto({
    required super.id,
    required super.currencyId,
    required super.name,
    required super.fullName,
    required super.symbol,
    required super.rate,
    required super.partnerId,
    required super.partnerName
  });

  factory RateDto.fromJson(Map<String, dynamic> json) {

    return RateDto(
        id: json['id'] == false ? null : json['id'],
        currencyId: json['currency_id'] == false ? null : json['currency_id'],
        name: json['name'],
        fullName: json['fullName'],
        symbol: json['symbol'],
        rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
        partnerId: json['partner_id'] == false ? null : json['partner_id'],
        partnerName: json['partner_name']  == false ? null : json['partner_name']
    );
  }

  Rate toModel() {

    return Rate(
      id: id,
      currencyId: currencyId,
      name: name,
      fullName: fullName,
      symbol: symbol,
      rate: rate,
      partnerId: partnerId,
      partnerName: partnerName
    );
  }

}
