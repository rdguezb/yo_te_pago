import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/setting_options.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/auth_notifier.dart';


class SettingsView extends ConsumerWidget {

  static const name = AppRoutes.settings;

  const SettingsView( {super.key} );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final userRole = authState.session?.user.roleName;

    final availableOptions = allSettingOptions
        .where((option) => option.isVisibleFor(userRole)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTitles.settings),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Icon(
                      Icons.settings,
                      color: colors.primary,
                      size: 60),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.symmetric(vertical: 16.0)),

              _SettingsMenuList(options: availableOptions),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuList extends StatelessWidget {
  final List<SettingOption> options;

  const _SettingsMenuList({required this.options});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
          final option = options[index];
          final hasSubtitle = option.subtitle != null && option.subtitle!.trim().isNotEmpty;
          final hasPath = option.routeName != null && option.routeName!.trim().isNotEmpty;

          return ListTile(
            isThreeLine: hasSubtitle,
            leading: Icon(
                option.icon,
                color: colors.primary,
                size: 28),
            title: Text(
              option.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600
              )
            ),
            subtitle: hasSubtitle
                ? Text(option.subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withAlpha(179))
                  )
                : null,
            onTap: hasPath ? () => context.pushNamed(option.routeName!) : null,
            trailing: hasPath
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : null,
          );
        },
        childCount: options.length,
      ),
    );
  }
}
