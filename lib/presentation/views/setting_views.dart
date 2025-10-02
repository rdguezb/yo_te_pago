import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/setting_options.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/odoo_session_notifier.dart';


class SettingsView extends ConsumerStatefulWidget {

  const SettingsView( {super.key} );

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();

}


class _SettingsViewState extends ConsumerState<SettingsView> {

  @override
  Widget build(BuildContext context) {
    final userRole = ref.read(odooSessionNotifierProvider).session?.role;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final List<SettingOptions> options = settingOptions
        .where((o) => o.allowedRoles.contains(userRole))
        .toList();

    return Scaffold(
      appBar: AppBar(
          title: const Text(AppTitles.settings),
          centerTitle: true
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
                              size: 60
                          )
                      )
                  ),

                  const SliverPadding(
                      padding: EdgeInsets.symmetric(vertical: 16.0)
                  ),

                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                        final option = options[index];
                        final hasSubtitle = option.subtitle != null && option.subtitle!.trim().isNotEmpty;
                        final hasPath = option.path != null && option.path!.trim().isNotEmpty;

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
                                fontWeight: FontWeight.w600,
                                color: textTheme.titleMedium?.color)),
                          subtitle: hasSubtitle
                              ? Text(
                                option.subtitle!,
                                style: textTheme.bodySmall?.copyWith(color: colors.onSurface.withAlpha(179)))
                              : null,
                          onTap: hasPath
                              ? () => context.go(option.path!)
                              : null,
                          trailing: hasPath
                              ? const Icon(Icons.arrow_forward_ios, size: 16)
                              : null
                        );
                      },
                      childCount: options.length
                    )
                  )

                ]
            )
          )
      ),
    );
  }

}
