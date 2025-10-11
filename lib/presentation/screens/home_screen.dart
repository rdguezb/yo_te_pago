import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yo_te_pago/business/config/constants/app_roles.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';
import 'package:yo_te_pago/presentation/views/account_views.dart';
import 'package:yo_te_pago/presentation/views/dashboard_views.dart';
import 'package:yo_te_pago/presentation/views/rate_views.dart';
import 'package:yo_te_pago/presentation/views/report_views.dart';
import 'package:yo_te_pago/presentation/views/setting_views.dart';


class HomeScreen extends ConsumerStatefulWidget {

  static const name = AppRoutes.home;
  final int pageIndex;

  const HomeScreen({
    super.key,
    required this.pageIndex
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends ConsumerState<HomeScreen> with AutomaticKeepAliveClientMixin {

  late PageController _pageController;
  List<Widget> _pages = [];
  List<NavigationDestination> _navBarItems = [];
  int _effectivePageIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageIndex != oldWidget.pageIndex && _pageController.hasClients) {
      _pageController.animateToPage(
        _effectivePageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userRole = ref.watch(authNotifierProvider).session?.role;
    _buildPagesAndItems(userRole);

    if (_pages.isEmpty) {
      return const Scaffold(body: Center(child: Text('No tienes acceso a ninguna vista.')));
    }

    if (_pageController.hasClients && _pageController.page?.round() != _effectivePageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(_pageController.hasClients) {
          _pageController.jumpToPage(_effectivePageIndex);
        }
      });
    }

    return Scaffold(
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: _pages,
        ),
        bottomNavigationBar: _CustomBottomNavigationBar(
          destinations: _navBarItems,
          selectedIndex: _effectivePageIndex,
          onDestinationSelected: (index) {
            final selectedKey = _navBarItems[index].label.toLowerCase();

            if (selectedKey == 'salir') {
              ref.read(odooSessionNotifierProvider.notifier).logout();
            } else {
              _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut
              );
            }
          }
        )
    );
  }

  void _buildPagesAndItems(String? userRole) {
    final allPages = {
      'dashboard': DashboardView(key: ValueKey('dashboard_page')),
      'reports': ReportView(key: ValueKey('balance_page')),
      'rates': RatesView(key: ValueKey('rates_page')),
      'accounts': AccountViews(key: ValueKey('bank_page')),
      'settings': SettingsView(key: ValueKey('settings_page')),
    };

    final allNavBarItems = {
      'dashboard': const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Inicio'),
      'reports': const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          label: 'Reportes'),
      'rates': const NavigationDestination(
          icon: Icon(Icons.show_chart_outlined),
          label: 'Tasas'),
      'accounts': const NavigationDestination(
          icon: Icon(Icons.account_balance_outlined),
          label: 'Cuentas'),
      'settings': const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Ajustes'),
      'logout': const NavigationDestination(
          icon: Icon(Icons.logout_rounded),
          label: 'Salir'),
    };

    List<String> visibleItemKeys = [];
    if (userRole == ApiRole.manager || userRole == ApiRole.delivery)
      visibleItemKeys = ['dashboard', 'reports', 'rates', 'accounts', 'settings', 'logout'];
    else if (userRole == ApiRole.user)
      visibleItemKeys = ['dashboard', 'settings', 'logout'];
    else
      visibleItemKeys = [];

    _navBarItems = visibleItemKeys.map((key) => allNavBarItems[key]!).toList();

    final visiblePageKeys = visibleItemKeys.where((key) => key != 'logout').toList();
    _pages = visiblePageKeys.map((key) => allPages[key]!).toList();

    _effectivePageIndex = widget.pageIndex.clamp(0, _pages.isNotEmpty ? _pages.length - 1 : 0);
  }
}

class _CustomBottomNavigationBar extends StatelessWidget {

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final double elevation;

  const _CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.elevation = 0
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      elevation: elevation,
      destinations: destinations,
      indicatorColor: colors.primary.withAlpha(51)
    );
  }

}
