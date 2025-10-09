import 'package:flutter/material.dart';
import 'package:yo_te_pago/business/config/constants/app_roles.dart';


class SettingOptions {

  final String title;
  final IconData icon;
  final List<String> allowedRoles;
  final String? subtitle;
  final String? path;

  SettingOptions({
    required this.title,
    required this.icon,
    required this.allowedRoles,
    this.subtitle,
    this.path
  });

}

final List<SettingOptions> settingOptions = [
  SettingOptions(
    title: 'Mi Cuenta',
    icon: Icons.perm_identity_rounded,
    allowedRoles: const [ApiRole.delivery, ApiRole.user, ApiRole.manager],
    subtitle: 'Cambiar los datos de mi cuenta, mi nombre, etc.',
    path: '/setting/profile'
  ),
  SettingOptions(
      title: 'Clave de Acceso',
      icon: Icons.key_rounded,
      allowedRoles: const [ApiRole.delivery, ApiRole.user, ApiRole.manager],
      subtitle: 'Cambiar contraseña del usuario.',
      path: '/setting/password'
  ),
  SettingOptions(
      title: 'Usuarios',
      icon: Icons.group,
      allowedRoles: const [ApiRole.manager],
      subtitle: 'Creación/eliminación de usuarios en el sistema.',
      path: '/setting/users'
  ),
  SettingOptions(
      title: 'Monedas y Tasas',
      icon: Icons.monetization_on_outlined,
      allowedRoles: const [ApiRole.manager],
      subtitle: 'Asociar/Desasociar monedas para las remesas y tasas para el cambio.',
      path: '/setting/currencies'
  ),
  SettingOptions(
      title: 'Bancos',
      icon: Icons.account_balance_rounded,
      allowedRoles: const [ApiRole.manager],
      subtitle: 'Creación/eliminación de bancos.',
      path: '/setting/banks'
  ),
  SettingOptions(
      title: 'Cuentas de Bancos',
      icon: Icons.account_balance_wallet_rounded,
      allowedRoles: const [ApiRole.manager],
      subtitle: 'Creación/eliminación de cuentas de bancos.',
      path: '/setting/bank-accounts'
  ),
  SettingOptions(
      title: 'Privacidad',
      icon: Icons.lock_outline_rounded,
      allowedRoles: const [ApiRole.manager],
      subtitle: 'Definir comportamientos en la aplicación.',
      path: '/setting/settings'
  ),
  SettingOptions(
      title: 'Actualizaciones de la aplicacion',
      icon: Icons.install_mobile_rounded,
      allowedRoles: const [ApiRole.delivery, ApiRole.user, ApiRole.manager],
      path: '/setting/app-update'
  ),
];
