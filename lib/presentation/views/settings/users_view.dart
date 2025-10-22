import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:yo_te_pago/business/config/constants/app_messages.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';
import 'package:yo_te_pago/business/config/constants/forms.dart';
import 'package:yo_te_pago/business/config/constants/ui_text.dart';
import 'package:yo_te_pago/business/providers/users_provider.dart';
import 'package:yo_te_pago/presentation/widgets/shared/alert_message.dart';
import 'package:yo_te_pago/presentation/widgets/tiles/user_tile.dart';

class UsersView extends ConsumerStatefulWidget {

  static const name = AppRoutes.users;

  const UsersView({super.key});

  @override
  ConsumerState<UsersView> createState() => _UsersViewState();

}

class _UsersViewState extends ConsumerState<UsersView> {

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(usersProvider).users.isEmpty) {
        ref.read(usersProvider.notifier).loadNextPage();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        ref.read(usersProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final userState = ref.watch(usersProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    ref.listen(usersProvider, (previous, next) {
      if (previous != null && previous.errorMessage == null && next.errorMessage != null) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: next.errorMessage!,
          type: SnackBarType.error
        );
      }
      if (previous != null && !previous.lastUpdateSuccess && next.lastUpdateSuccess) {
        showCustomSnackBar(
          scaffoldMessenger: scaffoldMessenger,
          message: AppMessages.operationSuccess,
          type: SnackBarType.success
        );
      }
    });

    return Scaffold(
        appBar: AppBar(
            title: const Text(AppTitles.users),
            centerTitle: true
        ),
        floatingActionButton: FloatingActionButton(
            heroTag: 'addUser',
            onPressed: () => context.pushNamed(AppRoutes.userCreate),
            tooltip: 'Crear usuario',
            child: const Icon(Icons.add)
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: SafeArea(
            child: (userState.isLoading && userState.users.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => ref.read(usersProvider.notifier).refresh(),
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          SliverToBoxAdapter(
                              child: Center(
                                  child: Icon(
                                      Icons.group,
                                      color: colors.primary,
                                      size: 60
                                  )
                              )
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextFormField(
                                      onChanged: (query) {
                                        ref.read(usersProvider.notifier).setSearchQuery(query);
                                      },
                                      decoration: InputDecoration(
                                          hintText: AppFormLabels.hintNameSearch,
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0)
                                      )
                                  )
                              )
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                          _buildContent(userState, colors, context)
                        ]
                    )
                )
            )
        )
    );
  }

  Widget _buildContent(UsersState userState, ColorScheme colors, BuildContext context) {
    final filteredUsers = userState.filteredUsers;

    if (userState.isLoading && filteredUsers.isEmpty) {

      return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator())
      );
    }

    if (userState.errorMessage != null && filteredUsers.isEmpty) {
      return SliverFillRemaining(
          child: Center(
              child: Text(
                  userState.errorMessage!,
                  style: TextStyle(color: colors.error),
                  textAlign: TextAlign.center
              )
          )
      );
    }

    if (filteredUsers.isEmpty) {
      return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
              child: Text(
                  'No se encontraron usuarios!',
                  style: Theme.of(context).textTheme.titleMedium
              )
          )
      );
    }

    return SliverList(
        delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
          final user = filteredUsers[index];

          return UserTile(user: user);
        },
        childCount: filteredUsers.length
        )
    );
  }
}