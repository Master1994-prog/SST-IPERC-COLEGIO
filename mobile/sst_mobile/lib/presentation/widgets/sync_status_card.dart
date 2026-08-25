import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/sync_provider.dart';

/// ===============================================================
/// SYNC STATUS CARD - SST EDURISK
/// ===============================================================
///
/// Tarjeta reutilizable para mostrar el estado online/offline,
/// registros pendientes, errores y sincronización manual.
///
/// Colores oficiales SST EduRisk:
/// primary       #083F85
/// primaryBright #0D60D6
/// navyDark      #05295E
/// green         #1DA041
/// yellow        #FEB81C
/// riskOrange    #EC490F
/// ===============================================================
class SyncStatusCard extends StatelessWidget {
  const SyncStatusCard({
    super.key,
    this.showSyncButton = true,
    this.compact = false,
  });

  final bool showSyncButton;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (BuildContext context, SyncProvider provider, Widget? child) {
        final _SyncVisual visual = _getVisual(provider.status);

        final bool tienePendientes = provider.pendingCount > 0;

        final bool puedeSincronizar =
            provider.isConnected && !provider.isSynchronizing;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.navyDark.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  height: 5,
                  color: visual.color,
                ),
                Padding(
                  padding: EdgeInsets.all(compact ? 14 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SyncIcon(
                            visual: visual,
                            synchronizing: provider.isSynchronizing,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        visual.title,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _ConnectionBadge(
                                      connected: provider.isConnected,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  provider.message ??
                                      'Consultando estado de sincronización...',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 14 : 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _pendingColor(
                            provider,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _pendingColor(
                              provider,
                            ).withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              tienePendientes
                                  ? Icons.pending_actions_outlined
                                  : Icons.task_alt_outlined,
                              color: _pendingColor(provider),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    tienePendientes
                                        ? 'Registros pendientes'
                                        : 'Datos actualizados',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    tienePendientes
                                        ? '${provider.pendingCount} '
                                              '${provider.pendingCount == 1 ? 'registro pendiente' : 'registros pendientes'} '
                                              'de envío al servidor.'
                                        : 'No existen registros pendientes de sincronización.',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              constraints: const BoxConstraints(
                                minWidth: 38,
                                minHeight: 38,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: _pendingColor(provider),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                provider.pendingCount > 99
                                    ? '99+'
                                    : provider.pendingCount.toString(),
                                style: TextStyle(
                                  color: provider.pendingCount > 0
                                      ? AppColors.navyDark
                                      : Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (provider.isSynchronizing) ...<Widget>[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: const LinearProgressIndicator(
                            minHeight: 7,
                            color: AppColors.primaryBright,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Enviando información al servidor. '
                          'No cierres la aplicación durante este proceso.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (provider.hasError &&
                          provider.lastError != null &&
                          provider.lastError!.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.riskOrange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: AppColors.riskOrange.withValues(
                                alpha: 0.30,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.riskOrange,
                                size: 21,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  provider.lastError!,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showSyncButton) ...<Widget>[
                        const SizedBox(height: 16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: provider.isSynchronizing
                                    ? null
                                    : provider.refreshStatus,
                                icon: const Icon(Icons.refresh_outlined),
                                label: const Text('Actualizar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: provider.hasError
                                      ? AppColors.riskOrange
                                      : AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.border,
                                  disabledForegroundColor:
                                      AppColors.textSecondary,
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: puedeSincronizar
                                    ? provider.hasError
                                          ? provider.retrySynchronization
                                          : provider.synchronize
                                    : null,
                                icon: provider.isSynchronizing
                                    ? const SizedBox(
                                        width: 19,
                                        height: 19,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
                                        provider.hasError
                                            ? Icons.replay_outlined
                                            : Icons.sync_outlined,
                                      ),
                                label: Text(
                                  provider.isSynchronizing
                                      ? 'Sincronizando...'
                                      : provider.hasError
                                      ? 'Reintentar'
                                      : provider.isConnected
                                      ? 'Sincronizar ahora'
                                      : 'Sin conexión',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
          icon: Icons.cloud_off_outlined,
          color: AppColors.yellow,
          iconForeground: AppColors.navyDark,
        );

      case SyncStatus.synchronizing:
        return const _SyncVisual(
          title: 'Sincronizando',
          icon: Icons.sync_outlined,
          color: AppColors.primaryBright,
          iconForeground: AppColors.primaryBright,
        );

      case SyncStatus.completed:
        return const _SyncVisual(
          title: 'Sincronización completada',
          icon: Icons.cloud_done_outlined,
          color: AppColors.green,
          iconForeground: AppColors.green,
        );

      case SyncStatus.error:
        return const _SyncVisual(
          title: 'Error de sincronización',
          icon: Icons.sync_problem_outlined,
          color: AppColors.riskOrange,
          iconForeground: AppColors.riskOrange,
        );

      case SyncStatus.idle:
        return const _SyncVisual(
          title: 'Sistema conectado',
          icon: Icons.cloud_done_outlined,
          color: AppColors.primary,
          iconForeground: AppColors.primary,
        );
    }
  }

  Color _pendingColor(SyncProvider provider) {
    if (provider.hasError) {
      return AppColors.riskOrange;
    }

    if (provider.pendingCount > 0) {
      return AppColors.yellow;
    }

    return AppColors.green;
  }
}

class _SyncIcon extends StatelessWidget {
  const _SyncIcon({required this.visual, required this.synchronizing});

  final _SyncVisual visual;
  final bool synchronizing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: visual.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.center,
      child: synchronizing
          ? SizedBox(
              width: 25,
              height: 25,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: visual.iconForeground,
              ),
            )
          : Icon(visual.icon, color: visual.iconForeground, size: 29),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final Color color = connected ? AppColors.green : AppColors.yellow;

    final Color foreground = connected ? AppColors.green : AppColors.navyDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: connected ? 0.10 : 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            connected ? 'Online' : 'Offline',
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SyncVisual {
  const _SyncVisual({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconForeground,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color iconForeground;
}
