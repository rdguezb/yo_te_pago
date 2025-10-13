class BankAccount {

  int? id;
  String name;
  int bankId;
  String bankName;

  BankAccount({
    this.id,
    required this.name,
    required this.bankId,
    this.bankName = ''
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {

    return BankAccount(
        id: (json['id'] as int?) ?? 0,
        name: json['acc_number'] as String,
        bankId: (json['bank_id'] as int?) ?? 0,
        bankName: json['bank_name'] as String
    );
  }

  BankAccount copyWith({
    int? id,
    String? name,
    int? bankId,
    String? bankName
  }) {

    return BankAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        bankId: bankId ?? this.bankId,
        bankName: bankName ?? this.bankName
    );
  }

  Map<String, dynamic> toMap() {

    return {
      'id': id,
      'acc_number': name,
      'bank_id': bankId,
      'bank_name': bankName
    };
  }

  @override
  String toString() {

    return '$name - $bankName';
  }
}