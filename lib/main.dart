import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:yo_te_pago/presentation/entry_point.dart';


Future<void> main() async{
  await dotenv.load(fileName: '.env');

  runApp(const ProviderScope(
    child: MainApp(),
  ));
}
