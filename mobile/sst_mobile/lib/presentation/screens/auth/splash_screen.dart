import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'welcome_screen.dart';

/// ===============================================================
/// SPLASH SCREEN SST EDURISK
/// ===============================================================
///
/// Pantalla de presentación de la aplicación.
///
/// Se muestra después del splash nativo de Android/iOS y antes
/// de WelcomeScreen.
///
/// Utiliza el logotipo completo de SST EduRisk.
/// ===============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // =============================================================
  // ANIMACIÓN
  // =============================================================

  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;

  late final Animation<double> _scaleAnimation;

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _iniciarSplash();
  }

  // =============================================================
  // INICIAR SPLASH
  // =============================================================

  Future<void> _iniciarSplash() async {
    await _animationController.forward();

    // Mantiene el logo visible brevemente.
    await Future<void>.delayed(const Duration(milliseconds: 1200));

    if (!mounted) {
      return;
    }

    // Reemplaza el SplashScreen para que el usuario no pueda
    // volver a él pulsando el botón Atrás.
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
    );
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _animationController.dispose();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Image.asset(
                    'assets/images/sst_edurisk_logo_completo.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.health_and_safety_outlined,
                                size: 100,
                                color: Color(0xFF0A4A9E),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'SST EduRisk',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0A4A9E),
                                ),
                              ),
                            ],
                          );
                        },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
