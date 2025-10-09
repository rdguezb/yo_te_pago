import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:yo_te_pago/business/config/constants/app_auth_states.dart';
import 'package:yo_te_pago/business/config/constants/odoo_endpoints.dart';
import 'package:yo_te_pago/business/domain/entities/balance.dart';
import 'package:yo_te_pago/business/domain/entities/account.dart';
import 'package:yo_te_pago/business/domain/entities/bank_account.dart';
import 'package:yo_te_pago/business/domain/entities/currency.dart';
import 'package:yo_te_pago/business/domain/entities/rate.dart';
import 'package:yo_te_pago/business/domain/entities/remittance.dart';
import 'package:yo_te_pago/business/domain/entities/user.dart';
import 'package:yo_te_pago/business/domain/services/ibase_service.dart';
import 'package:yo_te_pago/business/exceptions/odoo_exceptions.dart';
import 'package:yo_te_pago/infrastructure/models/dtos/account_dto.dart';
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
    } on OdooException catch (e) {
      print('Error de Odoo al obtener remesas: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al obtener remesas: $e');
      throw OdooException('Ocurrió un error inesperado al procesar las remesas.');
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
        final serverMessage = response?['message'] ?? 'The server returned an unexpected response after creating the remittance.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('OdooException while adding remittance: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while adding remittance: $e');
      throw OdooException('An unexpected error occurred while processing the new remittance.');
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

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the remittance update.';
        throw OdooException(serverMessage);
      }

    } on OdooException catch (e) {
      print('OdooException while editing remittance with ID ${remittance.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while editing remittance with ID ${remittance.id}: $e');
      throw OdooException('An unexpected error occurred while updating the remittance.');
    }
  }

  @override
  Future<bool> confirmRemittance(Remittance remittance) async {
    final String url = '${OdooEndpoints.remittanceBase}/confirm/${remittance.id}';

    try {
      final dynamic response = await _sendJsonRequest(
        'PUT',
        url);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the remittance.';
        throw OdooException(serverMessage);
      }
    }  on OdooException catch (e) {
      print('OdooException while confirming remittance with ID ${remittance.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while confirming remittance with ID ${remittance.id}: $e');
      throw OdooException('An unexpected error occurred while confirming the remittance.');
    }
  }

  @override
  Future<bool> payRemittance(Remittance remittance) async {
    final String url = '${OdooEndpoints.remittanceBase}/pay/${remittance.id}';

    try {
      final dynamic response = await _sendJsonRequest(
          'PUT',
          url);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the payment.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('OdooException while paying remittance with ID ${remittance.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while paying remittance with ID ${remittance.id}: $e');
      throw OdooException('An unexpected error occurred while paying the remittance.');
    }
  }

  @override
  Future<bool> deleteRemittance(int id) async {
    final String url = '${OdooEndpoints.remittanceBase}/$id';

    try {
      final dynamic response = await _sendJsonRequest(
          'DELETE',
          url);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the deletion.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('OdooException while deleting remittance with ID $id: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while deleting remittance with ID $id: $e');
      throw OdooException('An unexpected error occurred while deleting the remittance.');
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
    } on OdooException catch (e) {
      print('OdooException while getting currencies: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while getting currencies: $e');
      throw OdooException('An unexpected error occurred while getting the currencies.');
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
    } on OdooException catch (e) {
      print('OdooException while getting rates: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while getting rates: $e');
      throw OdooException('An unexpected error occurred while getting the rates.');
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
        final serverMessage = response?['message'] ?? 'The server returned an unexpected response after creating the rate.';
        throw OdooException(serverMessage);
      }
    }on OdooException catch (e) {
      print('OdooException while adding rate: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while adding rate: $e');
      throw OdooException('An unexpected error occurred while adding the new rate.');
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

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the rate update.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('OdooException while changing rate with ID ${rate.id}: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while changing rate with ID ${rate.id}: $e');
      throw OdooException('An unexpected error occurred while changing the rate value!');
    }
  }

  @override
  Future<bool> deleteRate(int id) async {
    final String url = '${OdooEndpoints.rateBase}/$id';

    try {
      final dynamic response = await _sendJsonRequest(
          'DELETE',
          url);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the rate deletion.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('OdooException while deleting rate with ID $id: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while deleting rate with ID $id: $e');
      throw OdooException('An unexpected error occurred while deleting the rate.');
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
    } on OdooException catch (e) {
      print('OdooException while getting balances: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while getting balances: $e');
      throw OdooException('An unexpected error occurred while getting the balances.');
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

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'The server did not confirm the balance update.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('OdooException while updating balance: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unexpected error while updating balance: $e');
      throw OdooException('An unexpected error occurred while updating the balance.');
    }
  }

// Bank Accounts

  @override
  Future<List<Account>> getAccounts() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.bankAccountBase);

      final dynamic data = response['data'];

      List<AccountDto> accountDto;
      if (data is Map<String, dynamic>) {
        accountDto = [AccountDto.fromJson(data)];
      } else if (data is List) {
        accountDto = data
            .map((jsonItem) => AccountDto.fromJson(jsonItem as Map<String, dynamic>))
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
    } on OdooException catch (e) {
      print('Error de Odoo al obtener cuentas bancarias: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al obtener cuentas bancarias: $e');
      throw OdooException('Ocurrió un error inesperado al procesar las cuentas bancarias.');
    }
  }

  @override
  Future<bool> deleteAccount(Account account) async {
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

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'No success flag in response.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('Error de Odoo al desasociar cuenta bancaria: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al desasociar cuenta bancaria: $e');
      throw OdooException('An unexpected error occurred while unlinking the account.');
    }
  }

  @override
  Future<bool> linkAccount(Account account) async {
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

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'No success flag in response.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('Error de Odoo al asociar cuenta bancaria: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al asociar cuenta bancaria: $e');
      throw OdooException('An unexpected error occurred while linking the account.');
    }
  }

  @override
  Future<List<BankAccount>> getBankAccounts() async {
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
    } on OdooException catch (e) {
      print('Error de Odoo al obtener cuentas bancarias permitidas: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al obtener cuentas bancarias permitidas: $e');
      throw OdooException('Ocurrió un error inesperado al procesar las cuentas bancarias permitidas.');
    }
  }

// User

  @override
  Future<List<User>> getDeliveries() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.usersDeliveries);

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
    } on OdooException catch (e) {
      print('Error de Odoo al obtener usuarios: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al obtener usuarios: $e');
      throw OdooException('Ocurrió un error inesperado al procesar los usuarios.');
    }
  }

  @override
  Future<List<User>> getUsers() async {
    try {
      final dynamic response = await _sendJsonRequest(
          'GET',
          OdooEndpoints.usersBase);

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
    } on OdooException catch (e) {
      print('Error de Odoo al obtener usuarios: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al obtener usuarios: $e');
      throw OdooException('Ocurrió un error inesperado al procesar los usuarios.');
    }
  }

  @override
  Future<bool> editMyAccount(User user) async {
    final String url = '${OdooEndpoints.profile}/${user.id}';
    Map<String, dynamic> dataMap = user.toMap();


    try {
      final response = await _sendJsonRequest(
          'PUT',
          url,
          bodyParams: dataMap);

      if (response != null && response['success'] == true) {
        return true;
      } else {
        final serverMessage = response?['message'] ?? 'No success flag in response.';
        throw OdooException(serverMessage);
      }
    } on OdooException catch (e) {
      print('Error de Odoo al actualizar los datos de la cuenta: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error inesperado al actualizar los datos de la cuenta: $e');
      throw OdooException('An unexpected error occurred while updating the account preferences.');
    }

  }

}