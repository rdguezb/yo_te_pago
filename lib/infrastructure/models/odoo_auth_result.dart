import 'package:yo_te_pago/business/domain/entities/company.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';


class OdooAuth {
  
  final User user;
  final Company company;
  final List<Company> allowedCompanies;
  final String? sessionId;
  final String? serverURL;
  final String? databaseName;

  OdooAuth({
    required this.user,
    required this.company,
    required this.allowedCompanies,
    this.serverURL,
    this.databaseName,
    this.sessionId
  });

  factory OdooAuth.fromJson(Map<String, dynamic> json, {String? sessionId}) {
    final currentCompanyId = json['company_id'] as int;
    List<Company> companies = [];

    if (json['user_companies']?['allowed_companies'] is Map<String, dynamic>) {
      final allowedCompaniesMap = json['user_companies']['allowed_companies'] as Map<String, dynamic>;
      companies = allowedCompaniesMap.values
          .where((value) => value is Map<String, dynamic>)
          .map((value) => Company.fromJson(value as Map<String, dynamic>))
          .toList();
    }

    final Company currentCompany = companies.firstWhere(
      (c) => c.id == currentCompanyId,
      orElse: () => throw Exception('Error de datos: La compañía actual no fue encontrada en la lista de compañías permitidas.'),
    );

    final user = User.fromJson(json);

    return OdooAuth(
      user: user,
      company: currentCompany,
      allowedCompanies: companies,
      sessionId: sessionId,
      serverURL: json['web.base.url'] as String?,
      databaseName: json['db'] as String?,
    );
  }

  OdooAuth copyWith({
    User? user,
    Company? company,
    List<Company>? allowedCompanies,
    String? sessionId,
    String? serverURL,
    String? databaseName,
  }) {

    return OdooAuth(
      user: user ?? this.user,
      company: company ?? this.company,
      allowedCompanies: allowedCompanies ?? this.allowedCompanies,
      sessionId: sessionId ?? this.sessionId,
      serverURL: serverURL ?? this.serverURL,
      databaseName: databaseName ?? this.databaseName,
    );
  }

}
