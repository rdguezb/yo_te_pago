import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_general_states.dart';
import 'package:yo_te_pago/business/config/constants/app_routes.dart';


class LoadingScreen extends StatelessWidget {

  static const name = AppRoutes.loading;

  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage('assets/icons/icon.png'),
              width: 200,
              height: 200
            ),

            SizedBox(height: 40),

            CircularProgressIndicator(strokeWidth: 4),

            SizedBox(height: 20),

            Text(
              AppGeneralMessages.loading,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey
              )
            )
          ]
        )
      )
    );
  }

}