import 'package:flutter/material.dart';

import '../../../data/repositories/matriz_iperc_offline_repository.dart';

/// ===============================================================
/// PRUEBA IPERC OFFLINE
/// ===============================================================
///
/// Pantalla sencilla para comprobar que una matriz IPERC puede
/// almacenarse correctamente en SQLite.
///
/// IMPORTANTE:
///
/// Los IDs utilizados aquí son únicamente para una prueba técnica.
/// Deben existir realmente en los catálogos de la base de datos
/// si posteriormente se desea sincronizar este registro con MySQL.
/// ===============================================================
class IpercOfflineTestScreen extends StatefulWidget {
  const IpercOfflineTestScreen({super.key});

  @override
  State<IpercOfflineTestScreen> createState() => _IpercOfflineTestScreenState();
}

class _IpercOfflineTestScreenState extends State<IpercOfflineTestScreen> {
  // =============================================================
  // REPOSITORIO
  // =============================================================

  final MatrizIpercOfflineRepository _repository =
      MatrizIpercOfflineRepository();

  // =============================================================
  // ESTADO
  // =============================================================

  bool _isSaving = false;

  String _message = 'Sin registros de prueba';

  // =============================================================
  // GUARDAR MATRIZ DE PRUEBA
  // =============================================================

  Future<void> _saveTestMatrix() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;

      _message = 'Guardando matriz local...';
    });

    try {
      // ---------------------------------------------------------
      // CREAR MATRIZ OFFLINE
      // ---------------------------------------------------------
      //
      // El repositorio actual exige todos los IDs
      // organizacionales.
      //
      // Se utilizan IDs numéricos porque el repositorio valida
      // que sean identificadores válidos.
      // ---------------------------------------------------------

      final matriz = await _repository.createOffline(
        institucionId: '1',

        sedeId: '1',

        areaId: '1',

        puestoTrabajoId: '1',

        procesoId: '1',

        actividadId: '1',

        codigo: 'IPERC-TEST-${DateTime.now().millisecondsSinceEpoch}',

        nombre: 'Matriz IPERC administrativa de prueba',

        descripcion:
            'Registro creado localmente para comprobar '
            'el funcionamiento del modo offline.',

        fechaEvaluacion: DateTime.now().toUtc(),
      );

      if (!mounted) {
        return;
      }

      // ---------------------------------------------------------
      // RESULTADO
      // ---------------------------------------------------------

      setState(() {
        _message =
            'Guardado correctamente.\n\n'
            'ID local:\n'
            '${matriz.idLocal}\n\n'
            'Estado: pendiente de sincronización.';
      });
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Error de validación:\n'
            '${error.message ?? error}';
      });
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Error de sesión:\n'
            '${error.message}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Error al guardar:\n$error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba IPERC offline')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.cloud_off_outlined, size: 90),

              const SizedBox(height: 24),

              Text(_message, textAlign: TextAlign.center),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTestMatrix,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar matriz offline',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Esta pantalla es únicamente para comprobar '
                'el almacenamiento local SQLite.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
