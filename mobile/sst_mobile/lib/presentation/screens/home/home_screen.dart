import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.nombreUsuario, required this.rol, super.key});

  static const String routeName = '/home';

  final String nombreUsuario;
  final String rol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SST - IPERC')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Bienvenido, $nombreUsuario',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Rol: $rol'),
            const SizedBox(height: 32),
            const Card(
              child: ListTile(
                leading: Icon(Icons.assignment),
                title: Text('Matrices IPERC'),
                subtitle: Text('Registrar y consultar evaluaciones.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
