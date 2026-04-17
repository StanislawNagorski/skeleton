// TODO(plan-02): Replace with Drift database. ObjectBox removed in Phase 2.
// This stub preserves the interface until Plan 02 completes migration.

import 'package:path_provider/path_provider.dart' as p;

/// Legacy ObjectBox wrapper -- stubbed pending Drift migration.
abstract class ObjectBox {
  static bool _initialized = false;

  static Future<void> initObjectBox() async {
    // Stub: fetch docs dir to validate path_provider works.
    await p.getApplicationDocumentsDirectory();
    _initialized = true;
  }

  /// Returns whether the store has been initialized.
  static bool get isInitialized => _initialized;

  static void close() {
    _initialized = false;
  }
}
