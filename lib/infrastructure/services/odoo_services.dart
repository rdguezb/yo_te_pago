import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:yo_te_pago/business/config/constants/app_auth_states.dart';
import 'package:yo_te_pago/business/config/constants/odoo_endpoints.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/domain/entities/bank.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/company.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/entities/role.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/domain/services/ibase_service.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/account_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/bank_account_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/bank_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/currency_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/role_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/user_dto.dart';
import 'package:yo_te_pago/infrastructure/models/odoo_auth_result.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/balance_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/rate_dto.dart';
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
  User get user => _authResult!.user;

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

    Map<String, dynamic>? finalBodyParams = bodyParams;
    if (finalBodyParams != null && finalBodyParams.containsKey('jsonrpc') && finalBodyParams['jsonrpc'] == '2.0' && _authResult != null && _authResult!.company.id != 0) {
      try {
        Map<String, dynamic> params = Map<String, dynamic>.from(finalBodyParams['params'] ?? {});
        Map<String, dynamic> kwargs = Map<String, dynamic>.from(params['kwargs'] ?? {});
        Map<String, dynamic> context = Map<String, dynamic>.from(kwargs['context'] ?? {});
        context['company_id'] = _authResult!.company.id;
        kwargs['context'] = context;
        params['kwargs'] = kwargs;
        finalBodyParams['params'] = params;
      } catch (e) {
        throw Exception('Error interno al preparar el contexto de la compañía');
      }
    }
    final requestBody = jsonEncode(finalBodyParams ?? {});

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
          String specificMessage = errorData['message'];
          final errorDetails = errorData['data'] as Map<String, dynamic>?;

          if (errorDetails != null && errorDetails.containsKey('name')) {
            specificMessage =  '$specificMessage - ${errorDetails['name']}';
          }
          if (specificMessage.isNotEmpty) {
            throw Exception(specificMessage);
          }

          throw Exception('Odoo reportó un error desconocido.');
        }
        if (decodedResponse.containsKey('result')) {
          final resultData = decodedResponse['result'];
          if (resultData is Map<String, dynamic> &&
              resultData.containsKey('error')) {
            final errorData = resultData['error'];
            final String? specificMessage;
            final errorDetails = errorData['data'] as Map<String, dynamic>?;
            if (errorDetails != null && errorDetails.containsKey('message')) {
              specificMessage = errorDetails['message'];
            } else {
              specificMessage = errorData['message'];
            }
            if (specificMessage != null && specificMessage.isNotEmpty) {
              throw Exception(specificMessage);
            }
          }
          return resultData;
        }
      }

      return decodedResponse;
    } else {
      throw Exception('Error en la petición: Código ${response.statusCode} - Cuerpo: ${response.body}');
    }
  }

  List<T> _parseResponseToList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    if (data == null) {
      return [];
    }
    if (data is Map<String, dynamic>) {
      return [fromJson(data)];
    } else if (data is List) {
      return data.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } else {
      return [];
    }
  }

  Future<T> _handleRequest<T>(Future<T> Function() requestFunction, {required String errorContext}) async {
    try {

      return await requestFunction();
    } on OdooException catch (e) {
      print('OdooException en $errorContext: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado en $errorContext: $e');
      throw OdooException('Ocurrió un error inesperado durante la operación en $errorContext.');
    }
  }

  Future<bool> authenticate(String login, String password) async {
    try {
      final debugUri = Uri.parse('http://10.0.2.2:8069/web/database/list');
      print('--- DEBUG: INTENTANDO CONECTAR A http://10.0.2.2:8069 ---');
      final debugResponse = await http.post(
        debugUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'jsonrpc': '2.0', 'method': 'call', 'params': {}}),
      ).timeout(const Duration(seconds: 10));
      print('--- DEBUG SUCCESS ---');
      print('--- DEBUG STATUS: ${debugResponse.statusCode} ---');
    } catch (e) {
      print('--- DEBUG FAILED: ${e.toString()} ---');
    }

    print('----- Autenticando con login: $login');
    print('----- Autenticando con pass: $password');

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

        print('--- SESSION ID: $sessionId ---');
        print('--- RESULT: $result ---');

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
      print('--- ERROR DE CONEXIÓN (ClientException) en Autenticación: ${e.message} ---');
      throw Exception('Error de red. Por favor, revisa tu conexión a internet.');
    } catch (e) {
      print('--- ERROR DESCONOCIDO en Autenticación: $e ---');
      throw OdooException('Ocurrió un error inesperado durante la autenticación.');
    }
  }

  Future<void> logout() async {
    if (_authResult?.sessionId == null) return;
    final uri = Uri.parse('$baseUrl${OdooEndpoints.logout}');
    try {
      final response = await http.get(
        uri, headers: {'Cookie': _authResult!.sessionId ?? ''});

      if (response.statusCode == 200 || response.statusCode == 303) {
        _authResult = null;
      } else {
        print('OdooService: Error al cerrar sesión: ${response.statusCode} - ${response.body}');
        throw Exception('OdooService: Error al cerrar sesión: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('OdooService: Error desconocido al cerrar sesión: $e');
      throw Exception('OdooService: Error desconocido al cerrar sesión');
    }
    _authResult = null;
  }

// Remittances

  @override
  Future<List<Remittance>> getRemittances({int? id}) async {

    return _handleRequest(() async {
          String url = OdooEndpoints.remittanceBase;
          if (id != null) {
            url = '$url/$id';
          }

          final response = await _sendJsonRequest('GET', url);
          final dtos = _parseResponseToList(response['data'], RemittanceDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de remesas'
    );
  }

  @override
  Future<Remittance> addRemittance(Remittance remittance) async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'POST', OdooEndpoints.remittanceBase, bodyParams: remittance.toMap());
          final data = response['data'];

          if (data is Map<String, dynamic>) {
            return Remittance.fromJson(data);
          } else {
            throw OdooException(response['message'] ?? 'El servidor devolvió una respuesta inesperada.');
          }
        },
        errorContext: 'creación de remesa');
  }

  @override
  Future<bool> editRemittance(Remittance remittance) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.remittanceBase}/${remittance.id}';

          final response = await _sendJsonRequest(
              'PUT', url, bodyParams: remittance.toMap());

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la actualización de la remesa.');
          }
        },
        errorContext: 'edición de remesa');
  }

  @override
  Future<bool> confirmRemittance(int id) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.remittanceBase}/confirm/$id';

          final response = await _sendJsonRequest('PUT', url);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'confirmación de remesa');
  }

  @override
  Future<bool> payRemittance(int id) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.remittanceBase}/pay/$id';

          final response = await _sendJsonRequest('PUT', url);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'pago de remesa');
  }

  @override
  Future<bool> deleteRemittance(int id) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.remittanceBase}/$id';

          final response = await _sendJsonRequest('DELETE', url);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'eliminación de remesa');
  }

// Rates

  @override
  Future<List<Rate>> getRates({int? id}) async {

    return _handleRequest(() async {
          String url = OdooEndpoints.rateBase;
          if (id != null) {
            url = '$url/$id';
          }

          final response = await _sendJsonRequest('GET', url);
          final dtos = _parseResponseToList(response['data'], RateDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de tasas'
    );
  }

  @override
  Future<Rate> addRate(Rate rate) async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'POST', OdooEndpoints.rateBase, bodyParams: rate.toMap());
          final data = response['data'];

          if (data is Map<String, dynamic>) {
            return Rate.fromJson(data);
          } else {
            throw OdooException(response['message'] ?? 'El servidor devolvió una respuesta inesperada.');
          }
        },
        errorContext: 'creación de tasa');
  }

  @override
  Future<bool> changeRate(Rate rate) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.rateBase}/${rate.id}';
          final body = {
            'params': {
              'data': rate.toMap()
            }
          };
          final response = await _sendJsonRequest(
              'PUT', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'cambio del valor de la tasa');
  }

  @override
  Future<bool> deleteRate(int id) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.rateBase}/$id';

          final response = await _sendJsonRequest('DELETE', url);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'eliminación de tasa');
  }

// Currencies

  @override
  Future<List<Currency>> getAllowCurrencies() async {

    return _handleRequest(() async {
      final response = await _sendJsonRequest('GET', OdooEndpoints.allowCurrencies);
      final dtos = _parseResponseToList(response['data'], CurrencyDto.fromJson);

      return dtos.map((dto) => dto.toModel()).toList();
    },
        errorContext: 'obtención de monedas permitidas'
    );
  }

  @override
  Future<List<Currency>> getCurrencies({int limit = 20, int offset = 0}) async {

    return _handleRequest(() async {
          final queryParams = {'limit': limit, 'offset': offset};

          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.currencyBase, queryParams: queryParams);

          final dtos = _parseResponseToList(response['data'], CurrencyDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de monedas'
    );
  }

  @override
  Future<bool> toggleCurrencyActive(int currencyId) async {

    return _handleRequest(() async {
      final url = '${OdooEndpoints.currencyBase}/$currencyId';
      final response = await _sendJsonRequest('POST', url);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
      }
    },
    errorContext: 'activar/desactivar moneda');
  }

  @override
  Future<bool> updateCurrencyRate(int currencyId, double rate) async {

    return _handleRequest(() async {
      final url = '${OdooEndpoints.currencyBase}/$currencyId';
      final body = {
        'params': {
          'data': rate
        }
      };

      final response = await _sendJsonRequest('PUT', url, bodyParams: body);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
      }
    },
    errorContext: 'actualizar tasa de moneda');
  }

// Balances

  @override
  Future<List<Balance>> getBalances() async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.balanceBase);
          final dtos = _parseResponseToList(response['data'], BalanceDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de saldos'
    );
  }

  @override
  Future<bool> updateBalance(int currencyId, int partnerId, double amount, String type) async {

    return _handleRequest(() async {
          final body = {
            'amount': amount,
            'currency_id': currencyId,
            'partner_id': partnerId,
            'action': type};
          final response = await _sendJsonRequest(
              'POST', OdooEndpoints.balanceBase, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'actualización de saldos'
    );
  }

// Accounts

  @override
  Future<List<Account>> getAccounts() async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.accountBase);

          final dtos = _parseResponseToList(response['data'], AccountDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de cuentas de banco'
    );
  }

  @override
  Future<bool> deleteAccount(int partnerId, int accountId) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.accountBase}/$partnerId';
          final body = {
            'bank_id': accountId,
            'action': 'unlink'
          };

          final response = await _sendJsonRequest('PUT', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'desasociar cuenta bancaria');
  }

  @override
  Future<bool> linkAccount(int partnerId, int accountId) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.accountBase}/$partnerId';
          final body = {
            'bank_id': accountId,
            'action': 'link'
          };

          final response = await _sendJsonRequest('PUT', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'asociar cuenta bancaria');
  }

// Bank Accounts

  @override
  Future<List<BankAccount>> getBankAccounts() async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.bankAccountBase);
          final dtos = _parseResponseToList(response['data'], BankAccountDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de cuentas de banco'
    );
  }

  @override
  Future<BankAccount> addBankAccount(BankAccount bankAccount) async {

    return _handleRequest(() async {
          final body = {
            'params': {
              'data': bankAccount.toMap()
            }
          };
          final response = await _sendJsonRequest(
              'POST', OdooEndpoints.bankAccountBase, bodyParams: body);
          final data = response['data'];

          if (data is Map<String, dynamic>) {
            return BankAccount.fromJson(data);
          } else {
            throw OdooException(response['message'] ?? 'El servidor devolvió una respuesta inesperada.');
          }
        },
        errorContext: 'creación de cuenta de banco');
  }

  @override
  Future<bool> deleteBankAccount(int bankAccountId) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.bankAccountBase}/$bankAccountId';

          final response = await _sendJsonRequest('DELETE', url);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'eliminar cuenta bancaria');
  }

  @override
  Future<bool> updateBankAccount(BankAccount bankAccount) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.bankAccountBase}/${bankAccount.id}';
          final body = {
            'params': {
              'data': bankAccount.toMap()
            }
          };

          final response = await _sendJsonRequest('PUT', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'actualizar cuenta bancaria');
  }

// Banks

  @override
  Future<List<Bank>> getBanks() async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.bankBase);
          final dtos = _parseResponseToList(response['data'], BankDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de bancos'
    );
  }

  @override
  Future<Bank> addBank(Bank bank) async {

    return _handleRequest(() async {
          final body = {
            'params': {
              'data': bank.toMap()
            }
          };
          final response = await _sendJsonRequest(
              'POST', OdooEndpoints.bankBase, bodyParams: body);
          final data = response['data'];

          if (data is Map<String, dynamic>) {
            return Bank.fromJson(data);
          } else {
            throw OdooException(response['message'] ?? 'El servidor devolvió una respuesta inesperada.');
          }
        },
        errorContext: 'creación de banco');
  }

  @override
  Future<bool> updateBank(Bank bank) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.bankBase}/${bank.id}';
          final body = {
            'params': {
              'data': bank.toMap()
            }
          };

          final response = await _sendJsonRequest('PUT', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'actualizar banco');
  }

// User & Roles

  @override
  Future<List<User>> getDeliveries() async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.usersDeliveries);
          final dtos = _parseResponseToList(response['data'], UserDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de remeseros'
    );
  }

  @override
  Future<List<User>> getUsers({int limit = 20, int offset = 0}) async {

    return _handleRequest(() async {
          final queryParams = {'limit': limit, 'offset': offset};

          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.usersBase, queryParams: queryParams);

          final dtos = _parseResponseToList(response['data'], UserDto.fromJson);

          return dtos.map((dto) => dto.toModel()).toList();
        },
        errorContext: 'obtención de usuarios'
    );
  }

  @override
  Future<bool> editUser(User user) async {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.profile}/${user.id}';
          final body = {
            'params': {
              'data': user.toMap()
            }
          };

          final response = await _sendJsonRequest('PUT', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'actualizar usuario');
  }

  @override
  Future<bool> adminSetUserPassword(int userId, String newPassword) {

    return _handleRequest(() async {
      final url = '${OdooEndpoints.usersBase}/$userId/password';
      final body = {
        'params': {
          'data': {
            'password': newPassword
          }
        }
      };

      final response = await _sendJsonRequest('PUT', url, bodyParams: body);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
      }
    },
        errorContext: 'actualizar contraseña de usuario');
  }

  @override
  Future<bool> userChangeOwnPassword({required String oldPassword, required String newPassword}) {
    return _handleRequest(() async {
          const url = OdooEndpoints.profileChangePassword;
          final body = {
            'params': {
              'old_password': oldPassword,
              'new_password': newPassword,
            }
          };

          final response = await _sendJsonRequest('POST', url, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no pudo cambiar la contraseña.');
          }
        },
        errorContext: 'cambio de contraseña propia');
  }

  @override
  Future<User> createUser(Map<String, dynamic> user) {

    return _handleRequest(() async {
      final body = {
        'params': {
          'data': user
        }
      };
      final response = await _sendJsonRequest(
          'POST', OdooEndpoints.usersBase, bodyParams: body);
      final data = response['data'];

      if (data is Map<String, dynamic>) {
        return User.fromJson(data);
      } else {
        throw OdooException(response['message'] ?? 'El servidor devolvió una respuesta inesperada.');
      }
    },
        errorContext: 'creación de usuario');
  }

  @override
  Future<bool> deleteUser(int userId) {

    return _handleRequest(() async {
          final url = '${OdooEndpoints.usersBase}/$userId';

          final response = await _sendJsonRequest('DELETE', url);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'eliminar usuario');
  }

   @override
  Future<List<Role>> getRoles() {

    return _handleRequest(() async {

      final response = await _sendJsonRequest(
          'GET', OdooEndpoints.roleBase);

      print('----- $response');


      final dtos = _parseResponseToList(response['data'], RoleDto.fromJson);

      return dtos.map((dto) => dto.toModel()).toList();
    },
        errorContext: 'obtención de roles'
    );
  }

// Settings

  @override
  Future<Map<String, dynamic>> getParameters() async {

    return _handleRequest(() async {
          final response = await _sendJsonRequest(
              'GET', OdooEndpoints.settingsBase);

          if (response['data'] is Map<String, dynamic>) {
            return response['data'];
          } else {
            return {};
          }
        },
        errorContext: 'obtención de parametros'
    );
  }

  @override
  Future<bool> updateParameters(Company company) async {

    return _handleRequest(() async {
          final body = {
            'params': {
              'data': company.toMap()
            }
          };

          final response = await _sendJsonRequest(
              'PUT', OdooEndpoints.settingsBase, bodyParams: body);

          if (response != null && response['success'] == true) {
            return true;
          } else {
            throw OdooException(response['message'] ?? 'El servidor no confirmó la operación.');
          }
        },
        errorContext: 'actualizar parametros');
  }

 }