import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_lifecycle_sync.dart';
import '../providers/sync_provider.dart';

class AppLifecycleSyncListener extends StatefulWidget {
  const AppLifecycleSyncListener({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleSyncListener> createState() =>
      _AppLifecycleSyncListenerState();
}

class _AppLifecycleSyncListenerState extends State<AppLifecycleSyncListener> {
  AppLifecycleSync? _lifecycleSync;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_lifecycleSync == null) {
      final SyncProvider syncProvider = context.read<SyncProvider>();

      _lifecycleSync = AppLifecycleSync(syncProvider: syncProvider);

      _lifecycleSync!.start();
    }
  }

  @override
  void dispose() {
    _lifecycleSync?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
