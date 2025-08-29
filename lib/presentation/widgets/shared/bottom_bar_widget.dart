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

  const CustomBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 0,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true
  });

  void _onItemTapped(BuildContext context, int index, WidgetRef ref, List<BottomBarItem> currentItems) {
    final tappedItem = currentItems.elementAt(index);

    if (tappedItem.label == 'Salir') {
      ref.read(odooSessionNotifierProvider.notifier).logout();
    } else {
      context.go(tappedItem.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final odooSessionState = ref.read(odooSessionNotifierProvider);
    final userRole = odooSessionState.session?.role;

    final List<BottomBarItem> roleNavItems = appBottomNavigationItems.values
        .where((item) => item.allowedRoles.contains(userRole))
        .toList();
    final List<BottomNavigationBarItem> _navItems = roleNavItems.map((item) {
      return BottomNavigationBarItem(
        icon: Icon(item.icon),
        activeIcon: Icon(item.icon, color: colors.primary),
        label: item.label,
        backgroundColor: colors.surface,
      );
    }).toList();

    return BottomNavigationBar(
        currentIndex: selectedIndex.clamp(0, _navItems.length - 1),
        onTap: (value) => _onItemTapped(context, value, ref, roleNavItems),
        elevation: elevation,
        selectedItemColor: selectedItemColor ?? colors.primary,
        unselectedItemColor: unselectedItemColor ?? colors.onSurface.withAlpha((255 * 0.6).round()),
        showSelectedLabels: showSelectedLabels,
        showUnselectedLabels: showUnselectedLabels,
        type: BottomNavigationBarType.fixed,
        items: _navItems);
  }

}
