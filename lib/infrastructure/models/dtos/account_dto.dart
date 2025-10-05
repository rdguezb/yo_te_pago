import 'package:yo_te_pago/business/domain/entities/account.dart';


class AccountDto extends Account {

  AccountDto({
    required super.id,
    required super.name,
    required super.bankName,
    super.partnerId,
    super.partnerName
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) {

    return AccountDto(
        id: (json['id'] as int?) ?? 0,
        name: (json['acc_number'] as String?) ?? 'N/A',
        bankName: (json['bank_name'] as String?) ?? 'No Bank',
        partnerId: (json['partner_id'] as int?) ?? 0,
        partnerName: (json['partner_name'] as String?) ?? ''
    );
  }

  Account toModel() {

    return Account(
        id: id,
        name: name,
        bankName: bankName,
        partnerId: partnerId,
        partnerName: partnerName
    );
  }

}
