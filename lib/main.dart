import 'package:flutter/material.dart';
import 'modules/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const NutriFlowApp());
}

class NutriFlowApp extends StatelessWidget {
  const NutriFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriFlow',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}