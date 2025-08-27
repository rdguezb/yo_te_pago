import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/bottom_bar_items.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';

class CustomBottomNavigationBar extends ConsumerWidget {

  final int selectedIndex;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  static const List<String> navRoutes = [
    '/home/0',
    '/home/1',
    '/home/2',
    '/home/3',
  ];

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 0,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true
  });

  void _onItemTapped(BuildContext context, int index, WidgetRef ref) {
    final String tappedItemKey = appBottomNavigationItems.keys.elementAt(index);
    if (tappedItemKey == 'Salir') {
      ref.read(odooSessionNotifierProvider.notifier).logout();
    } else {
      if (index >= 0 && index < navRoutes.length) {
        final route = navRoutes[index];
        context.go(route);
      }
    }
  }

  static final List<BottomNavigationBarItem> _navItems = appBottomNavigationItems.entries.map((entry) =>
      BottomNavigationBarItem(
        icon: Icon(entry.value),
        activeIcon: Icon(entry.value, color: Colors.blue),
        label: entry.key,
        backgroundColor: Colors.white,
      )).toList();


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return BottomNavigationBar(
        currentIndex: selectedIndex.clamp(0, _navItems.length - 1),
        onTap: (value) => _onItemTapped(context, value, ref),
        elevation: elevation,
        selectedItemColor: selectedItemColor ?? colors.primary,
        unselectedItemColor: unselectedItemColor ?? colors.onSurface.withAlpha((255 * 0.6).round()),
        showSelectedLabels: showSelectedLabels,
        showUnselectedLabels: showUnselectedLabels,
        type: BottomNavigationBarType.fixed,
        items: _navItems);
  }

}
