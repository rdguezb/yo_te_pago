import 'package:yo_te_pago/business/domain/entities/company.dart';


class OdooAuth {
  final int userId;
  final String userName;
  final int partnerId;
  final String partnerName;
  final int companyId;
  final List<Company> allowedCompanies;
  final String? sessionId;
  final String? serverURL;
  final String? databaseName;

  OdooAuth({
    required this.userId,
    required this.userName,
    required this.partnerId,
    required this.partnerName,
    required this.companyId,
    required this.allowedCompanies,
    this.serverURL,
    this.databaseName,
    this.sessionId
  });

  factory OdooAuth.fromJson(Map<String, dynamic> json, {String? sessionId}) {
    final id = json['company_id'] as int;
    List<Company> companies = [];
    if (json.containsKey('user_companies') && json['user_companies'] is Map<String, dynamic>) {
      final userCompaniesData = json['user_companies'] as Map<String, dynamic>;
      if (userCompaniesData.containsKey('allowed_companies') && userCompaniesData['allowed_companies'] is Map<String, dynamic>) {
        final allowedCompaniesMap = userCompaniesData['allowed_companies'] as Map<String, dynamic>;
        allowedCompaniesMap.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            companies.add(Company.fromJson(value));
          }
        });
      }
    }

    return OdooAuth(
      userId: json['uid'] as int,
      userName: json['username'] as String,
      partnerId: json['partner_id'] as int,
      partnerName: json['name'] as String,
      companyId: id,
      allowedCompanies: companies,
      sessionId: sessionId
    );
  }

  OdooAuth copyWith({
    String? userName,
    String? partnerName,
    int? companyId,
    List<Company>? allowedCompanies
  }) {

    return OdooAuth(
      userId: userId,
      userName: userName ?? this.userName,
      partnerId: partnerId,
      partnerName: partnerName ?? this.partnerName,
      companyId: companyId ?? this.companyId,
      allowedCompanies: allowedCompanies ?? this.allowedCompanies,
      sessionId: sessionId,
      serverURL: serverURL,
      databaseName: databaseName

    );
  }

}