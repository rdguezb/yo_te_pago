import 'package:flutter/material.dart';

import 'package:yo_te_pago/presentation/views/bank_views.dart';
import 'package:yo_te_pago/presentation/views/dashboard_views.dart';
import 'package:yo_te_pago/presentation/views/rate_views.dart';
import 'package:yo_te_pago/presentation/views/report_views.dart';
import 'package:yo_te_pago/presentation/views/setting_views.dart';
import 'package:yo_te_pago/presentation/widgets/shared/bottom_bar_widget.dart';


class HomeScreen extends StatefulWidget {

  static const name = 'home';
  final int pageIndex;

  const HomeScreen({
    super.key,
    required this.pageIndex
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {

  late PageController _pageController;
  final _pages =  <Widget>[
    DashboardView(key: ValueKey('dashboard_page')),
    ReportView(key: ValueKey('balance_page')),
    RatesView(key: ValueKey('rates_page')),
    BankViews(key: ValueKey('bank_page')),
    SettingsView(key: ValueKey('settings_page')),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
        initialPage: widget.pageIndex.clamp(0, _pages.length - 1),
        keepPage: true
    );
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageIndex != oldWidget.pageIndex) {
      final int effectivePageIndex = widget.pageIndex.clamp(0, _pages.length - 1);
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          effectivePageIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: _pages,
        ),
        bottomNavigationBar: CustomBottomNavigationBar(selectedIndex: widget.pageIndex)
    );
  }

}
