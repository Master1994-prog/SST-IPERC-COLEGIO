import 'package:flutter/material.dart';

import '../../../core/network/network_info.dart';
import '../../../core/services/sync_service.dart';
import '../../../data/datasources/local/sync_queue_local_datasource.dart';

class SyncTestScreen extends StatefulWidget {
  const SyncTestScreen({super.key});

  @override
  State<SyncTestScreen> createState() => _SyncTestScreenState();
}

class _SyncTestScreenState extends State<SyncTestScreen> {
  final SyncService _syncService = SyncService();

  final SyncQueueLocalDatasource _queueDatasource = SyncQueueLocalDatasource();

  bool _isLoading = false;
  bool _isConnected = false;
  int _pendingCount = 0;
  String _message = 'Presiona actualizar para comprobar.';

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final bool connected = await NetworkInfo.instance.isConnected;

    final int pending = await _queueDatasource.countPending();

    if (!mounted) {
      return;
    }

    setState(() {
      _isConnected = connected;
      _pendingCount = pending;
    });
  }

  Future<void> _synchronize() async {
    setState(() {
      _isLoading = true;
      _message = 'Sincronizando registros...';
    });

    try {
      final SyncResult result = await _syncService.synchronizePending();

      if (!mounted) {
        return;
      }

      if (result.withoutConnection) {
        setState(() {
          _message =
              'No hay conexión a internet. Los datos permanecen guardados localmente.';
        });
      } else {
        setState(() {
          _message =
              'Total: ${result.total}\n'
              'Sincronizados: ${result.synchronized}\n'
              'Errores: ${result.failed}';
        });
      }

      await _refreshStatus();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Error general: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización IPERC')),
      body: RefreshIndicator(
        onRefresh: _refreshStatus,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              size: 90,
              color: _isConnected ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              _isConnected
                  ? 'Con conexión a internet'
                  : 'Sin conexión a internet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: const Icon(Icons.pending_actions),
                title: const Text('Registros pendientes'),
                trailing: Text(
                  '$_pendingCount',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(_message, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isLoading ? null : _synchronize,
              icon: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Sincronizar pendientes'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _refreshStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar estado'),
            ),
          ],
        ),
      ),
    );
  }
}
