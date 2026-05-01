import 'package:flutter/material.dart';
import 'core/database/local_database.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/presentation/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.init();
  runApp(const NutriFlowApp());
}

class NutriFlowApp extends StatelessWidget {
  const NutriFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginPage(),
    );
  }
}
