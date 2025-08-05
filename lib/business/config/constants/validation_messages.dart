abstract class AppValidation {

  static const required = 'Este campo es requerido';
  static const invalidNumber = 'Debe ser un número válido';
  static const positiveNumber = 'Debe ser mayor que cero';
  static const currencySelection  = 'Seleccione una moneda';

}

abstract class AppStates {

  static const noRates = 'No existen tasas disponibles !';
  static const noCurrencies = 'No existen monedas disponibles !';
  static const noData = 'No hay datos disponibles !';
  static const noRemittance = 'No hay remesas registradas o no encontradas !';
  static const noBalance = 'No hay balances disponibles !';

  static const registerSuccess = 'Registro exitoso';
  static const registerFailure = 'Error en el registro !';

  static const inProcess = 'Procesando...';
  static const loading = 'Cargando...';

  static const remittanceConfirmed = 'Remesa ya confirmada y no se puede editar !';
  static const remittancePaidSuccess = 'Remesa marcada como pagada exitosamente';
  static const remittancePaidError = 'No se pudo marcar la remesa como pagada !';
  static const remittanceDeletedSuccess = 'Remesa eliminada exitosamente';
  static const remittanceDeletedError = 'No se pudo eliminar la remesa !';
  static const noEditedRemittance = 'No se pudo editar la remesa !';
  static const noPaidRemittance = 'No se pudo cambiar a pagada la remesa !';

  static const noEditedUser = 'No se pudo editar el usuario !';
  static const noEditedPartner = 'No se pudo editar el Partner !';

  static const noOdooConectionforRemittances = 'No hay conexión activa con Odoo para obtener remesas !';
  static const noOdooConectionforCurrencies = 'No hay conexión activa con Odoo para obtener monedas !';
  static const noOdooConectionforBalances = 'No hay conexión activa con Odoo para obtener balance !';

  static const noCredentialsFound = 'No se encontraron credenciales guardadas. Inicie sesión !';
  static const noCredentialsConfig = 'No se encontraron credenciales guardadas. Por favor, configúrelas !';
  static const failedToRestoreSession = 'Fallo al autenticar la sesión restablecida !';
  static const failedToLogin = 'Fallo al iniciar sesión !';
  static const noSessionOrProcess = 'OdooService no disponible: No hay sesión activa o está en proceso !';
  static const noSession = 'No autenticado. Por favor, inicie sesión primero !';
  static const noCookie = 'Cookie de sesión no encontrada después de la autenticación !';
  static const noLogin = 'Usuario no logueado. No se pueden obtener compañías permitidas !';

}
