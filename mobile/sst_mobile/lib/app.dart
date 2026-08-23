import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/sync_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/splash_screen.dart';
import 'presentation/widgets/app_lifecycle_sync_listener.dart';

class SstIpercApp extends StatelessWidget {
  const SstIpercApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SyncProvider>(
      create: (_) {
        final SyncProvider provider = SyncProvider();

        provider.initialize();

        return provider;
      },
      child: AppLifecycleSyncListener(
        child: MaterialApp(
          title: 'SST EduRisk',

          debugShowCheckedModeBanner: false,

          theme: AppTheme.lightTheme,

          // =====================================================
          // PANTALLA INICIAL
          // =====================================================
          //
          // Primero se muestra el splash de identidad visual.
          // SplashScreen redirige posteriormente a WelcomeScreen.
          // =====================================================
          home: const SplashScreen(),

          routes: <String, WidgetBuilder>{
            LoginScreen.routeName: (_) => const LoginScreen(),
          },
        ),
      ),
    );
  }
}
