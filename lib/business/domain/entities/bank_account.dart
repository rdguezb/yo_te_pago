class BankAccount {

  int? id;
  String name;
  String bankName;

  BankAccount({
    this.id,
    required this.name,
    required this.bankName
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {

    return BankAccount(
        id: (json['id'] as int?) ?? 0,
        name: json['acc_number'] as String,
        bankName: json['bank_name'] as String
    );
  }

  BankAccount copyWith({
    int? id,
    String? name,
    String? bankName
  }) {

    return BankAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        bankName: bankName ?? this.bankName
    );
  }

  @override
  String toString() {

    return '$name - $bankName';
  }
}