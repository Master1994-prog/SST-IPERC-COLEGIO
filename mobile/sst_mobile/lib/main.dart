import 'package:flutter/material.dart';

import 'app.dart';
import 'core/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crea o abre SQLite antes de iniciar la interfaz.
  await AppDatabase.instance.database;

  runApp(const SstIpercApp());
}
