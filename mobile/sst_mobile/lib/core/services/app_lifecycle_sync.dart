import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../presentation/providers/sync_provider.dart';
import 'iperc_catalog_preload_service.dart';

/// ===============================================================
/// SINCRONIZACIÓN AL VOLVER A LA APLICACIÓN
/// ===============================================================
///
/// Este observador se activa cuando la app vuelve al primer plano.
///
/// Al reanudarse:
///
/// 1. Actualiza el estado de conectividad.
/// 2. Si existe Internet:
///    - Precarga/actualiza los catálogos IPERC en SQLite.
///    - Sincroniza operaciones pendientes.
///
/// De esta forma, los catálogos necesarios para:
///
/// "Agregar peligro evaluado"
///
/// se mantienen disponibles para una futura sesión offline, incluso
/// si el usuario no vuelve a iniciar sesión.
///
/// ===============================================================
class AppLifecycleSync extends WidgetsBindingObserver {
  AppLifecycleSync({
    required this.syncProvider,
    IpercCatalogPreloadService? catalogPreloadService,
  }) : _catalogPreloadService =
           catalogPreloadService ?? IpercCatalogPreloadService();

  // =============================================================
  // DEPENDENCIAS
  // =============================================================

  final SyncProvider syncProvider;

  final IpercCatalogPreloadService _catalogPreloadService;

  // =============================================================
  // ESTADO INTERNO
  // =============================================================

  /// Evita iniciar varias rutinas de reanudación simultáneamente.
  bool _procesandoReanudacion = false;

  /// Indica si el observador ya fue registrado.
  bool _iniciado = false;

  // =============================================================
  // START
  // =============================================================

  void start() {
    if (_iniciado) {
      return;
    }

    WidgetsBinding.instance.addObserver(this);

    _iniciado = true;
  }

  // =============================================================
  // STOP
  // =============================================================

  void stop() {
    if (!_iniciado) {
      return;
    }

    WidgetsBinding.instance.removeObserver(this);

    _iniciado = false;
  }

  // =============================================================
  // CAMBIO DE ESTADO
  // =============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    // El callback de lifecycle no puede ser async directamente.
    // Lanzamos la rutina y capturamos internamente cualquier fallo.
    unawaited(_procesarReanudacion());
  }

  // =============================================================
  // PROCESAR REANUDACIÓN
  // =============================================================

  Future<void> _procesarReanudacion() async {
    if (_procesandoReanudacion) {
      return;
    }

    _procesandoReanudacion = true;

    try {
      // ---------------------------------------------------------
      // 1. ACTUALIZAR CONECTIVIDAD Y PENDIENTES
      // ---------------------------------------------------------

      await syncProvider.refreshStatus();

      // ---------------------------------------------------------
      // 2. SIN INTERNET
      // ---------------------------------------------------------

      if (!syncProvider.isConnected) {
        return;
      }

      // ---------------------------------------------------------
      // 3. ACTUALIZAR CATÁLOGOS IPERC
      // ---------------------------------------------------------
      //
      // No bloqueamos la sincronización si un catálogo falla.
      // El servicio conserva siempre la última copia SQLite válida.
      // ---------------------------------------------------------

      try {
        await _catalogPreloadService.preload();
      } catch (_) {
        // La actualización de catálogos es complementaria.
        // Nunca debe impedir la sincronización de datos pendientes.
      }

      // ---------------------------------------------------------
      // 4. SINCRONIZAR PENDIENTES
      // ---------------------------------------------------------

      if (syncProvider.pendingCount > 0) {
        await syncProvider.synchronize();
      }
    } catch (_) {
      // Un evento de lifecycle nunca debe cerrar ni bloquear la app.
    } finally {
      _procesandoReanudacion = false;
    }
  }
}
