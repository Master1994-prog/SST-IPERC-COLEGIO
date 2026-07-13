import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _goToLogin(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'La pantalla de inicio de sesión se creará en el siguiente paso.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Spacer(),

              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety,
                  size: 85,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                'SST - IPERC',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Sistema móvil para la gestión de Seguridad y Salud '
                'en el Trabajo en instituciones educativas.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.5),
              ),

              const SizedBox(height: 32),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      _buildFeature(
                        context,
                        icon: Icons.assignment_outlined,
                        title: 'Matrices IPERC',
                        description: 'Registrar peligros, riesgos y controles.',
                      ),
                      const Divider(height: 28),
                      _buildFeature(
                        context,
                        icon: Icons.cloud_sync_outlined,
                        title: 'Modo online y offline',
                        description:
                            'Trabajar sin internet y sincronizar después.',
                      ),
                      const Divider(height: 28),
                      _buildFeature(
                        context,
                        icon: Icons.security_outlined,
                        title: 'Información segura',
                        description:
                            'Protección y control de acceso por usuario.',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              FilledButton.icon(
                onPressed: () => _goToLogin(context),
                icon: const Icon(Icons.login),
                label: const Text(
                  'Ingresar al sistema',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Versión inicial 1.0.0',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
