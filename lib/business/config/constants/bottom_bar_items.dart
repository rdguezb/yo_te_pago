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
  'Inicio': BottomBarItem(
    label: 'Inicio',
    icon: Icons.home,
    path: '/home/0',
    allowedRoles: [ApiRole.delivery, ApiRole.user, ApiRole.manager]
  ),
  'Balance': BottomBarItem(
    label: 'Balance',
    icon: Icons.calculate_outlined,
    path: '/home/1',
    allowedRoles: [ApiRole.delivery, ApiRole.manager],
  ),
  'Configurar': BottomBarItem(
    label: 'Configurar',
    icon: Icons.manage_accounts_outlined,
    path: '/home/2',
    allowedRoles: [ApiRole.delivery, ApiRole.user, ApiRole.manager]
  ),
  'Salir': BottomBarItem(
    label: 'Salir',
    icon: Icons.logout,
    path: '',
    allowedRoles: [ApiRole.delivery, ApiRole.user, ApiRole.manager]
  )
};
