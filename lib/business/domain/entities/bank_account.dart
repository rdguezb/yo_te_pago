class BankAccount {

  int? id;
  String name;
  String bankName;
  int? partnerId;
  String? partnerName;

  BankAccount({
    this.id,
    required this.name,
    required this.bankName,
    this.partnerId,
    this.partnerName
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {

    return BankAccount(
        id: (json['id'] as int?) ?? 0,
        name: json['acc_number'],
        bankName: json['bank_name'],
        partnerId: (json['partner_id'] as int?) ?? 0,
        partnerName: json['partner_name']
    );
  }

  BankAccount copyWith({
    int? id,
    String? name,
    String? bankName,
    int? partnerId,
    String? partnerName
  }) {

    return BankAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        bankName: bankName ?? this.bankName,
        partnerId: partnerId ?? this.partnerId,
        partnerName: partnerName ?? this.partnerName
    );
  }


  @override
  String toString() {

    return '$name - $bankName';
  }
}