// Phase 7C — Storage monitoring for low-space warnings.
// DEVIATION: dart:io doesn't expose free space without FFI/native plugin.
// Stub returns false. Infrastructure wired for Phase 8 activation.
// See CLAUDE.md Known Deviations.

/// Thin storage check following ConnectivityMonitor pattern.
/// Injectable for testing.
class StorageMonitor {
  final Future<bool> Function() _checkStorage;

  /// Production constructor: uses default (stub) check.
  StorageMonitor() : _checkStorage = _defaultCheck;

  /// Test constructor: inject custom check function.
  StorageMonitor.withCheck(this._checkStorage);

  /// Returns true if device storage is below threshold.
  Future<bool> isStorageLow() async {
    try {
      return await _checkStorage();
    } catch (_) {
      return false; // Safe default on check failure.
    }
  }

  // Phase 8 stub — real disk space detection requires platform channel
  // or disk_space package.
  static Future<bool> _defaultCheck() async => false;
}
