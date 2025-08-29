import 'package:flutter/material.dart';

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
    allowedRoles: ['delivery', 'user', 'manager']
  ),
  'Balance': BottomBarItem(
    label: 'Balance',
    icon: Icons.query_stats,
    path: '/home/1',
    allowedRoles: ['delivery', 'manager'],
  ),
  'Configurar': BottomBarItem(
    label: 'Configurar',
    icon: Icons.settings_outlined,
    path: '/home/2',
    allowedRoles: ['delivery', 'user', 'manager']
  ),
  // 'Remesar': BottomBarItem(
  //   label: 'Remesar',
  //   icon: Icons.account_balance_wallet_outlined,
  //   path: '/home/3',
  //   allowedRoles: ['delivery']
  // ),
  'Salir': BottomBarItem(
    label: 'Salir',
    icon: Icons.logout,
    path: '',
    allowedRoles: ['delivery', 'user', 'manager']
  )
};
