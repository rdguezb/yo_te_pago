import 'package:flutter/material.dart';

import 'package:yo_te_pago/presentation/widgets/shared/appbar_error_widget.dart';


class ErrorScreen extends StatelessWidget {

  final String errorMessage;

  const ErrorScreen({
    super.key,
    required this.errorMessage});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: const AppBarError(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                'Ha ocurrido un error:\n\n$errorMessage',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Regresar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
