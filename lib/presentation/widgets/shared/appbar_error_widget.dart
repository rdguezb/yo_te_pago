import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/ui_text.dart';


class AppBarError extends StatelessWidget implements PreferredSizeWidget {

  const AppBarError({super.key});

  @override
  Widget build(BuildContext context) {

    return AppBar(
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/icon-app.png',
              width: 60,
              height: 60
            ),
            const Text(
                AppTitles.error,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)
            )
          ]
        )
      ),
      automaticallyImplyLeading: false
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

}