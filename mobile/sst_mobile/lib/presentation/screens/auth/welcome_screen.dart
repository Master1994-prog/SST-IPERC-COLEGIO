import 'package:flutter/material.dart';

import '../../widgets/sync_status_card.dart';
import 'login_screen.dart';

/// ===============================================================
/// WELCOME SCREEN - SST EDURISK
/// ===============================================================
///
/// Pantalla principal de bienvenida.
///
/// Se muestra después de SplashScreen y permite:
///
/// - Presentar la identidad SST EduRisk.
/// - Mostrar las funciones principales.
/// - Mostrar el estado de sincronización.
/// - Acceder al inicio de sesión.
/// ===============================================================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // =============================================================
  // LOGIN
  // =============================================================

  void _goToLogin(BuildContext context) {
    Navigator.pushNamed(context, LoginScreen.routeName);
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: <Widget>[
              // =================================================
              // LOGO
              // =================================================
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/icons/sst_edurisk_icon_1024.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder:
                        (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return Icon(
                            Icons.health_and_safety_outlined,
                            size: 100,
                            color: colors.primary,
                          );
                        },
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // NOMBRE
              // =================================================
              Text(
                'SST EduRisk',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 8),

              // =================================================
              // SUBTÍTULO
              // =================================================
              Text(
                'Sistema Móvil de Gestión SST e IPERC',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                'Gestión de Seguridad y Salud en el Trabajo '
                'para instituciones educativas, con soporte '
                'online y offline.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.4),
              ),

              const SizedBox(height: 30),

              // =================================================
              // FUNCIONALIDADES
              // =================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _buildFeature(
                        context,
                        icon: Icons.assignment_outlined,
                        title: 'Matrices IPERC',
                        description:
                            'Registrar peligros, evaluar '
                            'riesgos y administrar controles.',
                      ),

                      const Divider(height: 28),

                      _buildFeature(
                        context,
                        icon: Icons.grid_view_outlined,
                        title: 'Evaluación de riesgos 5×5',
                        description:
                            'Evaluar probabilidad, severidad '
                            'y nivel de riesgo.',
                      ),

                      const Divider(height: 28),

                      _buildFeature(
                        context,
                        icon: Icons.cloud_sync_outlined,
                        title: 'Modo online y offline',
                        description:
                            'Continuar trabajando sin '
                            'internet y sincronizar después.',
                      ),

                      const Divider(height: 28),

                      _buildFeature(
                        context,
                        icon: Icons.security_outlined,
                        title: 'Información segura',
                        description:
                            'Control de acceso y protección '
                            'de la información por usuario.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // SINCRONIZACIÓN
              // =================================================
              const SyncStatusCard(),

              const SizedBox(height: 24),

              // =================================================
              // BOTÓN LOGIN
              // =================================================
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: () {
                    _goToLogin(context);
                  },
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Ingresar al sistema',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // VERSIÓN
              // =================================================
              Text(
                'SST EduRisk • Versión 2.0.0',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // TARJETA DE CARACTERÍSTICA
  // =============================================================

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
