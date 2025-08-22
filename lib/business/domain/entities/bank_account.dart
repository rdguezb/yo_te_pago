class BankAccount {

  final int id;
  final String name;
  final String bankName;

  BankAccount({
    required this.id,
    required this.name,
    required this.bankName
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {

    return BankAccount(
        id: json['id'],
        name: json['acc_number'],
        bankName: json['bank_name']
    );
  }

  @override
  String toString() {

    return '$name - $bankName';
  }
}