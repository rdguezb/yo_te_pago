class Account {

  int? id;
  String name;
  String bankName;
  int? partnerId;
  String? partnerName;

  Account({
    this.id,
    required this.name,
    required this.bankName,
    this.partnerId,
    this.partnerName
  });

  factory Account.fromJson(Map<String, dynamic> json) {

    return Account(
        id: (json['id'] as int?) ?? 0,
        name: json['acc_number'],
        bankName: json['bank_name'],
        partnerId: (json['partner_id'] as int?) ?? 0,
        partnerName: json['partner_name']
    );
  }

  Account copyWith({
    int? id,
    String? name,
    String? bankName,
    int? partnerId,
    String? partnerName
  }) {

    return Account(
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