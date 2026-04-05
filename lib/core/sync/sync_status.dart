class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncAt;

  const SyncStatus({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.lastSyncAt,
  });

  bool get hasFailures => failedCount > 0;
  bool get hasPending => pendingCount > 0;
  bool get isHealthy => !isSyncing && !hasFailures && !hasPending;
}
