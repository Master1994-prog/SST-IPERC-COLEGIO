import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/welcome_screen.dart';

class SstIpercApp extends StatelessWidget {
  const SstIpercApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SST IPERC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}
