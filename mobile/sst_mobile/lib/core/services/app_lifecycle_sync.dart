import 'package:flutter/widgets.dart';

import '../../presentation/providers/sync_provider.dart';

class AppLifecycleSync extends WidgetsBindingObserver {
  AppLifecycleSync({required this.syncProvider});

  final SyncProvider syncProvider;

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncProvider.refreshStatus().then((_) {
        if (syncProvider.isConnected && syncProvider.pendingCount > 0) {
          syncProvider.synchronize();
        }
      });
    }
  }
}
