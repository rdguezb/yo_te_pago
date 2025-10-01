import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:yo_te_pago/business/config/constants/app_auth_states.dart';
import 'package:yo_te_pago/business/config/constants/odoo_endpoints.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/domain/services/ibase_service.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/bank_account_dto.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/currency_dto.dart';
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

    Map<String, dynamic>? finalBodyParams = bodyParams;
    if (finalBodyParams != null && finalBodyParams.containsKey('jsonrpc') && finalBodyParams['jsonrpc'] == '2.0' && _authResult != null && _authResult!.companyId != 0) {
      try {
        Map<String, dynamic> params = Map<String, dynamic>.from(finalBodyParams['params'] ?? {});
        Map<String, dynamic> kwargs = Map<String, dynamic>.from(params['kwargs'] ?? {});
        Map<String, dynamic> context = Map<String, dynamic>.from(kwargs['context'] ?? {});
        context['company_id'] = _authResult!.companyId;
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

// Remittances

  @override
  Future<List<Remittance>> getRemittances({int? id}) async {
    String url = OdooEndpoints.remittanceBase;

    if (id != null) {
      url = '$url/$id';
    }
    try {
      final dynamic response = await _sendJsonRequest(
        'GET',
        url);
      final dynamic data = response['data'];

      List<RemittanceDto> remittancesDto;
      if (data is Map<String, dynamic>) {
        remittancesDto = [RemittanceDto.fromJson(data)];
      } else if (data is List) {
        remittancesDto = data
            .map((jsonItem) => RemittanceDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        remittancesDto = [];
      }

      return remittancesDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener remesas: $e');
      throw Exception('Error al obtener remesas');
    }
  }

  @override
  Future<Remittance> addRemittance(Remittance remittance) async {
    final body = remittance.toMap();

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.remittanceBase,
          bodyParams: body);

      final dynamic data = response['data'];

      if (data is Map<String, dynamic>) {
        final Remittance res = Remittance.fromJson(data);
        return res;
      } else {
        throw Exception('Respuesta del servidor inesperada o incompleta.');
      }
    } catch (e) {
      print('Error al crear remesa: $e');
      throw Exception('Error al añadir remesa');
    }
  }

  @override
  Future<bool> editRemittance(Remittance remittance) async {
    final String url = '${OdooEndpoints.remittanceBase}/${remittance.id}';
    Map<String, dynamic> dataMap = remittance.toMap();
    dataMap.remove('remittance_date');

    try {
      final dynamic response = await _sendJsonRequest(
        'PUT',
        url,
        bodyParams: dataMap);

      if (response != null && response.containsKey('message') && response['message'] == 'Remittance updated') {
        return true;
      } else {
        throw Exception('Actualización exitosa pero respuesta del servidor inesperada.');
      }

    } catch (e) {
      print('Error al actualizar remesa con ID ${remittance.id}: $e');
      throw Exception('Error al actualizar la remesa. Verifique los datos, ID o permisos.');
    }
  }

  @override
  Future<bool> confirmRemittance(Remittance remittance) async {
    final String url = '${OdooEndpoints.remittanceBase}/confirm/${remittance.id}';

    try {
      final dynamic response = await _sendJsonRequest(
        'PUT',
        url);

      if (response != null && response.containsKey('message') && response['message'] == 'Remittance confirmed') {
        return true;
      } else {
        throw Exception('Confirmación exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al confirmar remesa con ID ${remittance.id}: $e');
      throw Exception('Error al confirmar la remesa. Verifique el estado o los permisos.');
    }
  }

  @override
  Future<bool> payRemittance(Remittance remittance) async {
    final String url = '${OdooEndpoints.remittanceBase}/pay/${remittance.id}';

    try {
      final dynamic response = await _sendJsonRequest(
          'PUT',
          url);

      if (response != null && response.containsKey('message') && response['message'] == 'Remittance payed') {
        return true;
      } else {
        throw Exception('Pago exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al pagar remesa con ID ${remittance.id}: $e');
      throw Exception('Error al pagar la remesa. Verifique el estado o los permisos.');
    }
  }

  @override
  Future<bool> deleteRemittance(Remittance remittance) async {
    final String url = '${OdooEndpoints.remittanceBase}/${remittance.id}';

    try {
      final dynamic response = await _sendJsonRequest(
          'DELETE',
          url);

      if (response != null && response.containsKey('message') && response['message'] == 'Remittance deleted') {
        return true;
      } else {
        throw Exception('Eliminación exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al eliminar remesa con ID ${remittance.id}: $e');
      throw Exception('Error al eliminar la remesa. Verifique el estado o los permisos.');
    }
  }

// Rates & Currencies

  @override
  Future<List<Currency>> getAvailableCurrencies() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.getCurrencies);
      final dynamic data = response['data'];
      List<CurrencyDto> currencyDto;
      if (data is Map<String, dynamic>) {
        currencyDto = [CurrencyDto.fromJson(data)];
      } else if (data is List) {
        currencyDto = data
            .map((jsonItem) => CurrencyDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        currencyDto = [];
      }

      return currencyDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener monedas: $e');
      throw Exception('Error al obtener monedas');
    }
  }

  @override
  Future<List<Rate>> getRates({int? id}) async {
    String url = OdooEndpoints.rateBase;

    if (id != null) {
      url = '$url/$id';
    }
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          url);
      final dynamic data = response['data'];

      List<RateDto> ratesDto;
      if (data is Map<String, dynamic>) {
        ratesDto = [RateDto.fromJson(data)];
      } else if (data is List) {
        ratesDto = data
            .map((jsonItem) => RateDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        ratesDto = [];
      }

      return ratesDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener tasas: $e');
      throw Exception('Error al obtener tasas');
    }
  }

  @override
  Future<Rate> addRate(Rate rate) async {
    final body = rate.toMap();

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.rateBase,
          bodyParams: body);

      final dynamic data = response['data'];

      if (data is Map<String, dynamic>) {
        final Rate res = Rate.fromJson(data);
        return res;
      } else {
        throw Exception('Respuesta del servidor inesperada o incompleta.');
      }
    } catch (e) {
      print('Error al crear tasa: $e');
      throw Exception('Error al añadir tasa');
    }
  }

  @override
  Future<bool> changeRate(Rate rate) async {
    final String url = '${OdooEndpoints.rateBase}/${rate.id}';
    Map<String, dynamic> dataMap = rate.toMap();

    try {
      final dynamic response = await _sendJsonRequest(
          'PUT',
          url,
          bodyParams: dataMap);

      if (response != null && response.containsKey('message') && response['message'] == 'Rate updated') {
        return true;
      } else {
        throw Exception('Actualización exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al actualizar tasa con ID ${rate.id}: $e');
      throw Exception('Error al cambiar valor de la tasa!');
    }
  }

  @override
  Future<bool> deleteRate(Rate rate) async {
    final String url = '${OdooEndpoints.rateBase}/${rate.id}';

    try {
      final dynamic response = await _sendJsonRequest(
          'DELETE',
          url);

      if (response != null && response.containsKey('message') && response['message'] == 'Rate deleted') {
        return true;
      } else {
        throw Exception('Eliminación exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al eliminar tasa con ID ${rate.id}: $e');
      throw Exception('Error al eliminar tasa');
    }
  }

// Balances

  @override
  Future<List<Balance>> getBalances() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.balanceBase);

      final dynamic data = response['data'];

      List<BalanceDto> balanceDto;
      if (data is Map<String, dynamic>) {
        balanceDto = [BalanceDto.fromJson(data)];
      } else if (data is List) {
        balanceDto = data
            .map((jsonItem) => BalanceDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        balanceDto = [];
      }

      return balanceDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener saldos: $e');
      throw Exception('Error al obtener saldos');
    }
  }

  @override
  Future<bool> updateBalance(int currencyId, int partnerId, double amount, String type) async {
    final body = {
      'amount': amount,
      'currency_id': currencyId,
      'partner_id': partnerId,
      'action': type
    };

    try {
      final response = await _sendJsonRequest(
          'POST',
          OdooEndpoints.balanceBase,
          bodyParams: body);

      if (response != null && response.containsKey('message') && response['message'] == 'Balance updated') {
        return true;
      } else {
        throw Exception('Actualización exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al actualizar saldo: $e');
      throw Exception('Error al actualizar saldo');
    }
  }

// Bank Accounts

  @override
  Future<List<BankAccount>> getBankAccounts() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.bankAccountBase);

      final dynamic data = response['data'];

      List<BankAccountDto> accountDto;
      if (data is Map<String, dynamic>) {
        accountDto = [BankAccountDto.fromJson(data)];
      } else if (data is List) {
        accountDto = data
            .map((jsonItem) => BankAccountDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        accountDto = [];
      }

      if (accountDto.isEmpty) {
        return [];
      }

      return accountDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener cuentas bancarias: $e');
      throw Exception('Error al obtener cuentas bancarias');
    }
  }

  @override
  Future<bool> deleteBankAccount(BankAccount account) async {
    final String url = '${OdooEndpoints.bankAccountBase}/${account.partnerId}';
    final body = {
      'bank_id': account.id,
      'action': 'unlink'
    };

    try {
      final response = await _sendJsonRequest(
          'PUT',
          url,
          bodyParams: body);

      if (response != null && response.containsKey('message') && response['message'] == 'Bank Account Deleted') {
        return true;
      } else {
        throw Exception('Actualización exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al desasociar cuenta bancaria: $e');
      throw Exception('Error al desasociar cuenta bancaria');
    }
  }

  @override
  Future<bool> linkBankAccount(BankAccount account) async {
    final String url = '${OdooEndpoints.bankAccountBase}/${account.partnerId}';
    final body = {
      'bank_id': account.id,
      'action': 'link'
    };

    try {
      final response = await _sendJsonRequest(
          'PUT',
          url,
          bodyParams: body);

      if (response != null && response.containsKey('message') && response['message'] == 'Bank Account Deleted') {
        return true;
      } else {
        throw Exception('Actualización exitosa pero respuesta del servidor inesperada.');
      }
    } catch (e) {
      print('Error al sasociar cuenta bancaria: $e');
      throw Exception('Error al sasociar cuenta bancaria');
    }

  }

  @override
  Future<List<BankAccount>> getAllowedBankAccounts() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.bankAccountAllowBase);

      final dynamic data = response['data'];

      List<BankAccountDto> accountDto;
      if (data is Map<String, dynamic>) {
        accountDto = [BankAccountDto.fromJson(data)];
      } else if (data is List) {
        accountDto = data
            .map((jsonItem) => BankAccountDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        accountDto = [];
      }

      return accountDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener cuentas bancarias: $e');
      throw Exception('Error al obtener cuentas bancarias');
    }  }

// User

  @override
  Future<List<User>> getDeliveries() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.userDeliveries);

      final dynamic data = response['data'];

      List<UserDto> userDto;
      if (data is Map<String, dynamic>) {
        userDto = [UserDto.fromJson(data)];
      } else if (data is List) {
        userDto = data
            .map((jsonItem) => UserDto.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
      } else {
        userDto = [];
      }

      return userDto
          .map((dto) => dto.toModel())
          .toList();
    } catch (e) {
      print('Error al obtener usuarios: $e');
      throw Exception('Error al obtener usuarios');
    }
  }

  @override
  Future<bool> editPartner(String name) {
    // TODO: implement editPartner
    throw UnimplementedError();
  }

  @override
  Future<bool> editUser(String login) {
    // TODO: implement editUser
    throw UnimplementedError();
  }

}