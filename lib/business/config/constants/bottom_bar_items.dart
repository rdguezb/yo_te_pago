import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';


class BottomBarItem {
  final String label;
  final IconData icon;
  final String path;
  final List<String> allowedRoles;

  const BottomBarItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.allowedRoles
  });
}

const Map<String, BottomBarItem> appBottomNavigationItems = {
  'home': BottomBarItem(
    label: 'Inicio',
    icon: Icons.home,
    path: '/home/0',
    allowedRoles: [ApiRole.delivery, ApiRole.user, ApiRole.manager]
  ),
  'balance': BottomBarItem(
    label: 'Balance',
    icon: Icons.calculate_outlined,
    path: '/home/1',
    allowedRoles: [ApiRole.delivery, ApiRole.manager],
  ),
  'rate': BottomBarItem(
      label: 'Tasas de Cambio',
      icon: Icons.currency_exchange,
      path: '/home/2',
      allowedRoles: [ApiRole.delivery, ApiRole.manager]
  ),
  'bank': BottomBarItem(
      label: 'Cuentas',
      icon: Icons.account_balance_rounded,
      path: '/home/3',
      allowedRoles: [ApiRole.delivery, ApiRole.manager]
  ),
  'settings': BottomBarItem(
    label: 'Configurar',
    icon: Icons.manage_accounts_outlined,
    path: '/home/4',
    allowedRoles: [ApiRole.delivery, ApiRole.user]
  ),
  'config': BottomBarItem(
      label: 'Configurar',
      icon: Icons.settings,
      path: '/home/5',
      allowedRoles: [ApiRole.manager]
  ),
  'logout': BottomBarItem(
    label: 'Salir',
    icon: Icons.logout,
    path: '',
    allowedRoles: [ApiRole.delivery, ApiRole.user, ApiRole.manager]
  )
};
