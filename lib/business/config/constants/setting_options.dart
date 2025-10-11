import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';

abstract class SettingOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;

  const SettingOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName
  });

  bool isVisibleFor(String? userRole);
}

class ProfileSettingOption extends SettingOption {
  const ProfileSettingOption()
      : super(
          title: 'Mi Cuenta',
          subtitle: 'Cambiar los datos de mi cuenta, mi nombre, etc.',
          icon: Icons.perm_identity_rounded,
          routeName: AppRoutes.profile
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.delivery || userRole == ApiRole.user ||
        userRole == ApiRole.manager;
  }
}

class PasswordSettingOption extends SettingOption {
  const PasswordSettingOption()
      : super(
          title: 'Clave de Acceso',
          subtitle: 'Cambiar contraseña del usuario.',
          icon: Icons.key_rounded,
          routeName: AppRoutes.password
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.delivery || userRole == ApiRole.user ||
        userRole == ApiRole.manager;
  }
}

class UsersSettingOption extends SettingOption {
  const UsersSettingOption()
      : super(
          title: 'Usuarios',
          subtitle: 'Creación/eliminación de usuarios en el sistema.',
          icon: Icons.group,
          routeName: AppRoutes.users
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.manager;
  }
}

class CurrencyRateSettingOption extends SettingOption {
  const CurrencyRateSettingOption()
      : super(
          title: 'Monedas y Tasas',
          subtitle: 'Asociar/Desasociar monedas para las remesas y tasas para el cambio.',
          icon: Icons.monetization_on_outlined,
          routeName: AppRoutes.currency
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.manager;
  }
}

class BanksSettingOption extends SettingOption {
  const BanksSettingOption()
      : super(
          title: 'Bancos',
          subtitle: 'Creación/Eliminación de bancos.',
          icon: Icons.business_rounded,
          routeName: AppRoutes.banks
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.manager;
  }
}

class BankAccountsSettingOption extends SettingOption {
  const BankAccountsSettingOption()
      : super(
          title: 'Cuentas de Bancos',
          subtitle: 'Creación/eliminación de cuentas de bancos.',
          icon: Icons.account_balance_rounded,
          routeName: AppRoutes.bankAccount
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.manager;
  }
}

class PrivacySettingOption extends SettingOption {
  const PrivacySettingOption()
      : super(
          title: 'Privacidad',
          subtitle: 'Definir comportamientos y/o parametros en la aplicación.',
          icon: Icons.lock_outline_rounded,
          routeName: AppRoutes.settings
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.manager;
  }
}

class AppUpdateSettingOption extends SettingOption {
  const AppUpdateSettingOption()
      : super(
          title: 'Actualizaciones de la aplicacion',
          subtitle: '',
          icon: Icons.install_mobile_rounded,
          routeName: AppRoutes.appUpdate
        );

  @override
  bool isVisibleFor(String? userRole) {
    return userRole == ApiRole.delivery || userRole == ApiRole.user ||
        userRole == ApiRole.manager;
  }
}

final List<SettingOption> allSettingOptions = [
  const ProfileSettingOption(),
  const PasswordSettingOption(),
  const UsersSettingOption(),
  const CurrencyRateSettingOption(),
  const BanksSettingOption(),
  const BankAccountsSettingOption(),
  const PrivacySettingOption(),
  const AppUpdateSettingOption()
];
