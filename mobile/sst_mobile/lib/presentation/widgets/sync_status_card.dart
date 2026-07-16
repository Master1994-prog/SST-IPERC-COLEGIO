import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sync_provider.dart';

class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({super.key, this.showSyncButton = true});

  final bool showSyncButton;

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (BuildContext context, SyncProvider provider, Widget? child) {
        final _SyncVisual visual = _getVisual(provider.status);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: visual.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: provider.isSynchronizing
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: visual.color,
                              ),
                            )
                          : Icon(visual.icon, color: visual.color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            visual.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(provider.message ?? 'Consultando estado...'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    const Icon(Icons.pending_actions, size: 20),
                    const SizedBox(width: 8),
                    Text('Pendientes: ${provider.pendingCount}'),
                    const Spacer(),
                    if (showSyncButton)
                      TextButton.icon(
                        onPressed: provider.isSynchronizing
                            ? null
                            : provider.synchronize,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sincronizar'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _SyncVisual _getVisual(SyncStatus status) {
    switch (status) {
      case SyncStatus.offline:
        return const _SyncVisual(
          title: 'Modo offline',
          icon: Icons.cloud_off,
          color: Colors.orange,
        );

      case SyncStatus.synchronizing:
        return const _SyncVisual(
          title: 'Sincronizando',
          icon: Icons.sync,
          color: Colors.blue,
        );

      case SyncStatus.completed:
        return const _SyncVisual(
          title: 'Sincronización completada',
          icon: Icons.cloud_done,
          color: Colors.green,
        );

      case SyncStatus.error:
        return const _SyncVisual(
          title: 'Error de sincronización',
          icon: Icons.cloud_sync_outlined,
          color: Colors.red,
        );

      case SyncStatus.idle:
        return const _SyncVisual(
          title: 'Conectado',
          icon: Icons.cloud_done_outlined,
          color: Colors.green,
        );
    }
  }
}

class _SyncVisual {
  const _SyncVisual({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}
