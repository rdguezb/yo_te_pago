import 'package:flutter/material.dart';

import 'package:yo_te_pago/business/config/constants/app_general_states.dart';


class LoadingScreen extends StatelessWidget {

  static const name = 'loading-screen';

  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 4),
            SizedBox(height: 20),
            Text(
              AppGeneralMessages.loading,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey
              ),
            ),
          ],
        ),
      ),
    );
  }

}