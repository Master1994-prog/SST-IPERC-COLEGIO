import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/database/app_database.dart';
import 'presentation/providers/detalle_iperc_offline_provider.dart';

Future<void> main() async {
  // Inicializa Flutter antes de abrir SQLite.
  WidgetsFlutterBinding.ensureInitialized();

  // Crea o abre la base de datos local.
  await AppDatabase.instance.database;

  runApp(
    MultiProvider(
      providers: [
        // Administra los detalles IPERC guardados localmente.
        ChangeNotifierProvider<DetalleIpercOfflineProvider>(
          create: (_) =>
              DetalleIpercOfflineProvider()..actualizarCantidadPendientes(),
        ),
      ],
      child: const SstIpercApp(),
    ),
  );
}
