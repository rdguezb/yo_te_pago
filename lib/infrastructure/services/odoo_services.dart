import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:yo_te_pago/business/config/constants/app_auth_states.dart';
import 'package:yo_te_pago/business/config/constants/app_record_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_remittance_states.dart';
import 'package:yo_te_pago/business/config/constants/odoo_endpoints.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/company.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/services/ibase_service.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/bank_account_dto.dart';
import 'package:yo_te_pago/infrastructure/models/odoo_auth_result.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/balance_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/currency_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/remittance_dto.dart';


class OdooService extends IBaseService {

  late final String _baseUrl;
  late final String _databaseName;
  OdooAuth? _authResult;

  OdooService() {
    _baseUrl = dotenv.env['BASE_URL']!;
    _databaseName = dotenv.env['DB_NAME']!;
  }

  String get baseUrl => _baseUrl;
  String get databaseName => _databaseName;
  OdooAuth get odooSessionInfo => _authResult!;
  String get partnerName => _authResult!.partnerName;
  String? get userRole => _authResult!.role;

  Future<dynamic> _sendJsonRequest(String method, String path, {Map<String, dynamic>? bodyParams, Map<String, dynamic>? queryParams}) async {
    if (_authResult == null || _authResult!.sessionId == null) {
      throw Exception(AppAuthMessages.errorNoSessionOrProcess);
    }

    Uri uri;
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
    } else {
      uri = Uri.parse('$baseUrl$path');
    }

    if (bodyParams != null && bodyParams.containsKey('jsonrpc') && bodyParams['jsonrpc'] == '2.0' && _authResult != null && _authResult!.companyId != 0) {
      try {
        Map<String, dynamic> params = Map<String, dynamic>.from(bodyParams['params'] ?? {});
        Map<String, dynamic> kwargs = Map<String, dynamic>.from(params['kwargs'] ?? {});
        Map<String, dynamic> context = Map<String, dynamic>.from(kwargs['context'] ?? {});
        context['company_id'] = _authResult!.companyId;
        kwargs['context'] = context;
        params['kwargs'] = kwargs;
        bodyParams['params'] = params;
      } catch (e) {
        throw Exception('Error interno al preparar el contexto de la compañía');
      }
    }
    final requestBody = jsonEncode(bodyParams ?? {});

    final request = http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'application/json'
      ..headers['Cookie'] = _authResult!.sessionId!
      ..body = requestBody;

    final http.StreamedResponse streamedResponse = await http.Client().send(request);

    final http.Response response = await http.Response.fromStream(streamedResponse)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final dynamic decodedResponse = jsonDecode(response.body);
      if (decodedResponse is Map<String, dynamic>) {
        if (decodedResponse.containsKey('error')) {
          final errorData = decodedResponse['error'];
          throw Exception('Odoo API Error (${errorData['code'] ?? 'Desconocido'}): ${errorData['message'] ?? 'Error desconocido'} - ${errorData['data']['message'] ?? ''}');
        }
        if (decodedResponse.containsKey('result')) {
          return decodedResponse['result'];
        }
      }

      return decodedResponse;
    } else {
      throw Exception('Error en la petición: Código ${response.statusCode} - Cuerpo: ${response.body}');
    }
  }

  Future<List<T>> _handleResponse<T>(dynamic apiResponse, T Function(Map<String, dynamic>) fromJson) async {
    if (apiResponse is Map<String, dynamic>) {
      if (apiResponse.containsKey('error')) {
        final String? errorMessage = apiResponse['error'] as String?;
        final int? errorCode = apiResponse['code'] as int?;

        if (errorCode == 404 && errorMessage != null &&
            errorMessage.isNotEmpty) {
          return [];
        } else {
          throw Exception('Odoo Business Error (${errorCode ?? 'Desconocido'}): ${errorMessage ?? 'Error desconocido'}');
        }
      }
      if (apiResponse.containsKey('result')) {
        final dynamic resultData = apiResponse['result'];

        if (resultData == null) {
          return [];
        }

        if (resultData is List) {
          if (resultData.isEmpty) {
            return [];
          }
          return resultData
              .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        } else if (resultData is Map<dynamic, dynamic>) {
          return [fromJson(Map<String, dynamic>.from(resultData))];
        } else {
          throw Exception('Formato de "result" inesperado: Se esperaba una lista o mapa, se recibió: ${resultData.runtimeType}');
        }
      }
    }
    if (apiResponse is List) {
      if (apiResponse.isEmpty) {
        return [];
      }
      return apiResponse
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    throw Exception('Formato de respuesta API inesperado: ${apiResponse.runtimeType}');
  }

  Future<bool> authenticate(String login, String password) async {
    final uri = Uri.parse('$baseUrl${OdooEndpoints.authenticate}');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'db': databaseName,
            'login': login,
            'password': password,
          },
          'id': DateTime.now().millisecondsSinceEpoch,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('error')) {
          throw Exception('Error de autenticación: ${jsonResponse['error']['message'] ?? 'Error desconocido'}');
        }

        final Map<String, dynamic>? result = jsonResponse['result'] as Map<String, dynamic>?;
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader == null) {
          throw Exception(AppAuthMessages.errorNoCookie);
        }
        final cookieParts = setCookieHeader.split(';');
        String? sessionId;
        for (var part in cookieParts) {
          if (part.trim().startsWith('session_id=')) {
            sessionId = part.trim();
            break;
          }
        }
        if (result != null) {
          _authResult = OdooAuth.fromJson(result, sessionId: sessionId);

          return true;
        } else {
          throw Exception(AppAuthMessages.errorFailedToRestoreSession);
        }
      } else {
        throw Exception('Fallo la autenticación con código: ${response.statusCode} - ${response.body}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de red durante la autenticación');
    } catch (e) {
      throw Exception('Error desconocido durante la autenticación');
    }
  }

  Future<void> logout() async {
    final uri = Uri.parse('$baseUrl${OdooEndpoints.logout}');
    try {
      final response = await http.get(
        uri,
        headers: {
          'Cookie': _authResult!.sessionId ?? '',
        },
      );
      if (response.statusCode == 200 || response.statusCode == 303) {
        _authResult = null;
      } else {
        throw Exception('OdooService: Error al cerrar sesión: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('OdooService: Error desconocido al cerrar sesión');
    }
  }

  @override
  Future<List<Balance>> getBalances() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.getBalances);
      final List<BalanceDto> balances = await _handleResponse<BalanceDto>(
          response,
          (json) => BalanceDto.fromJson(json));

      return balances
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      throw Exception('Error al obtener saldos');
    }
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.getCurrencies);
      final List<CurrencyDto> currencies = await _handleResponse<CurrencyDto>(
        response,
        (json) => CurrencyDto.fromJson(json));

      return currencies
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      throw Exception('Error al obtener monedas');
    }
  }

  @override
  Future<List<Remittance>> getRemittances({int? id}) async {
    Map<String, dynamic>? queryParams;
    if (id != null) {
      queryParams = {'id': id.toString()};
    }
    try {
      final dynamic response = await _sendJsonRequest(
        'GET',
        OdooEndpoints.getRemittances,
        queryParams: queryParams);

      final List<RemittanceDto> remittances = await _handleResponse<RemittanceDto>(
          response,
          (json) => RemittanceDto.fromJson(json));

      return remittances
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      throw Exception('Error al obtener remesas');
    }
  }

  @override
  Future<Remittance> addRemittance(Remittance remittance) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'remittance.line',
        'method': 'create',
        'args': [remittance.toMap()],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      final int? id = response as int?;

      if (id == null || id == 0) {
        throw Exception('No se pudo crear la remesa.');
      }
      final createdRemittances = await getRemittances(id: id);
      if (createdRemittances.isEmpty) {
        throw Exception('No se pudo recuperar la remesa recién creada con ID: $id.');
      }

      return createdRemittances.first;
    } catch (e) {
      throw Exception('Error al añadir remesa');
    }
  }

  @override
  Future<bool> editRemittance(Remittance remittance) async {
    Map<String, dynamic> dataMap = remittance.toMap();
    dataMap.remove('remittance_date');
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'remittance.line',
        'method': 'write',
        'args': [
          [remittance.id],
          dataMap
        ],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      final bool success = response as bool;

      if (!success) {
        throw Exception(AppRecordMessages.errorNoEditedRecord);
      }

      return success;
    } catch (e) {
      throw Exception('Error al editar remesa');
    }
  }

  @override
  Future<bool> payRemittance(Remittance remittance) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'remittance.line',
        'method': 'action_pay',
        'args': [
          [remittance.id]
        ],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      final bool success = response as bool;

      if (!success) {
        throw Exception(AppRemittanceMessages.noPaidRemittance);
      }

      return success;
    } catch (e) {
      throw Exception('Error al cambiar a pagada la remesa');
    }
  }

  @override
  Future<bool> deleteRemittance(Remittance remittance) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'remittance.line',
        'method': 'unlink',
        'args': [
          [remittance.id]
        ],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      final bool success = response as bool;

      if (!success) {
        throw Exception('No se pudo eliminar la remesa con ID: ${remittance.id}.');
      }

      return success;
    } catch (e) {
      throw Exception('Error al eliminar remesa');
    }
  }

  @override
  Future<bool> editUser(String login) async {
    Map<String, dynamic> dataMap = {
      'login': login
    };
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'res.users',
        'method': 'write',
        'args': [
          [_authResult?.userId ?? 0],
          dataMap
        ],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      final bool success = response as bool;

      if (!success) {
        throw Exception(AppRecordMessages.errorNoEditedRecord);
      }
      if (_authResult != null) {
        _authResult = _authResult!.copyWith(userName: login);
      }

      return success;
    } catch (e) {
      throw Exception('Error al editar usuario');
    }
  }

  @override
  Future<bool> editPartner(String name) async {
    Map<String, dynamic> dataMap = {
      'name': name
    };
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'res.partner',
        'method': 'write',
        'args': [
          [_authResult?.partnerId ?? 0],
          dataMap
        ],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      final bool success = response as bool;

      if (!success) {
        throw Exception(AppRecordMessages.errorNoEditedRecord);
      }
      if (_authResult != null) {
        _authResult = _authResult!.copyWith(partnerName: name);
      }

      return success;
    } catch (e) {
      throw Exception('Error al editar cliente');
    }
  }

  Future<List<Company>> getUserAllowedCompanies() async {
    if (_authResult != null && _authResult!.allowedCompanies.isNotEmpty) {
      return _authResult!.allowedCompanies;
    }
    if (_authResult == null || _authResult!.userId == 0) {
      throw Exception(AppAuthMessages.errorNoAuthenticate);
    }

    try {
      final Map<String, dynamic> body = {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {
          'model': 'res.users',
          'method': 'read',
          'args': [
            [_authResult!.userId],
            ['company_ids', 'company_id']],
          'kwargs': {},
        },
        'id': DateTime.now().millisecondsSinceEpoch,
      };
      final dynamic result = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body
      );

      if (result is! List || result.isEmpty) {
        return [];
      }

      final userData = result[0] as Map<String, dynamic>;
      final List<dynamic> companyIds = userData['company_ids'] ?? [];
      final dynamic currentCompanyData = userData['company_id'];
      List<Company> fetchedCompanies = [];

      if (companyIds.isNotEmpty) {
        final Map<String, dynamic> companiesBody = {
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {
            'model': 'res.company',
            'method': 'read',
            'args': [companyIds],
            'kwargs': {},
          },
          'id': DateTime.now().millisecondsSinceEpoch,
        };
        final dynamic companiesDetails = await _sendJsonRequest(
            'POST',
            OdooEndpoints.callKw,
            bodyParams: companiesBody
        );

        if (companiesDetails is List) {
          for (var companyDetail in companiesDetails) {
            if (companyDetail is Map<String, dynamic>) {
              final Company company = Company.fromJson(companyDetail);
              fetchedCompanies.add(company);
            }
          }
        }
      }
      if (_authResult != null && fetchedCompanies.isNotEmpty) {
        final int? apiCurrentCompanyId = currentCompanyData is List ? currentCompanyData[0] : (currentCompanyData as int?);
        _authResult = _authResult!.copyWith(
          allowedCompanies: fetchedCompanies,
          companyId: apiCurrentCompanyId ?? _authResult!.companyId,
        );
      }

      return fetchedCompanies;
    } catch (e) {
      throw Exception('Error al obtener compañías permitidas');
    }
  }

  @override
  Future<List<BankAccount>> getBankAccounts() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.getBankAccount);
      final List<BankAccountDto> bankAccounts = await _handleResponse<BankAccountDto>(
          response,
          (json) => BankAccountDto.fromJson(json));

      return bankAccounts
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      throw Exception('Error al obtener cuentas bancarias');
    }
  }

  @override
  Future<bool> confirmRemittance(Remittance remittance) async {
    final body = {
      'jsonrpc': '2.0',
      'method': 'call',
      'params': {
        'model': 'remittance.line',
        'method': 'action_confirm',
        'args': [
          [remittance.id]
        ],
        'kwargs': {},
      },
      'id': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.callKw,
          bodyParams: body);
      print(response);
      final bool success = response as bool;

      if (!success) {
        throw Exception(AppRemittanceMessages.noConfirmRemittance);
      }

      return success;
    } catch (e) {
      print(e);
      throw Exception('Error al cambiar a confirmada la remesa');
    }
  }

}