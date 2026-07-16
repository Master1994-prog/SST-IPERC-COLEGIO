import 'package:flutter/material.dart';

import '../../../data/repositories/matriz_iperc_offline_repository.dart';

import 'package:provider/provider.dart';

import '../../providers/sync_provider.dart';

class IpercOfflineTestScreen extends StatefulWidget {
  const IpercOfflineTestScreen({super.key});

  @override
  State<IpercOfflineTestScreen> createState() => _IpercOfflineTestScreenState();
}

class _IpercOfflineTestScreenState extends State<IpercOfflineTestScreen> {
  final MatrizIpercOfflineRepository _repository =
      MatrizIpercOfflineRepository();

  bool _isSaving = false;
  String _message = 'Sin registros de prueba';

  Future<void> _saveTestMatrix() async {
    setState(() {
      _isSaving = true;
      _message = 'Guardando matriz local...';
    });

    try {
      final matriz = await _repository.createOffline(
        institucionId: 'INSTITUCION-DEMO',
        areaId: 'AREA-ADMINISTRATIVA',
        codigo: 'IPERC-001',
        nombre: 'Matriz IPERC administrativa',
        descripcion: 'Registro creado sin conexión para prueba.',
        fechaEvaluacion: DateTime.now(),
      );

      if (!mounted) {
        return;
      }

      await context.read<SyncProvider>().notifyLocalChange();

      setState(() {
        _message = 'Guardado correctamente.\nID local: ${matriz.idLocal}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Error al guardar: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba IPERC offline')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.cloud_off, size: 90),
            const SizedBox(height: 24),
            Text(_message, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveTestMatrix,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar matriz offline'),
            ),
          ],
        ),
      ),
    );
  }
}
