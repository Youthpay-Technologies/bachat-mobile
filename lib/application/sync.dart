part of 'controller.dart';

extension DeviceSynchronization on AppController {
  // Realtime is a wake-up signal; authoritative reads still pass through RLS
  // and the pending-write overlay, preserving unsent local changes.
  void requestRefresh() {
    if (_disposed || !signedIn || preview) return;
    if (syncing) {
      _refreshAgain = true;
      return;
    }
    final generation = _generation;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!_disposed && generation == _generation) unawaited(refresh());
    });
  }

  void _ensureMoneySubscription(String account) {
    if (!_observeRealtime || _subscribedAccount == account || client == null)
      return;
    _stopMoneySubscription();
    _subscribedAccount = account;
    final channel = client!.channel('account:$account:money');
    for (final table in [
      'profiles',
      'transactions',
      'budgets',
      'savings_goals',
    ]) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: table == 'profiles' ? 'id' : 'owner_id',
          value: account,
        ),
        callback: (_) {
          if (_subscribedAccount == account) requestRefresh();
        },
      );
    }
    _moneyChannel = channel;
    channel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          _subscribedAccount == account) {
        requestRefresh(); // Also catch changes missed during a reconnect.
      }
    });
  }

  void _stopMoneySubscription() {
    _syncDebounce?.cancel();
    _syncDebounce = null;
    final channel = _moneyChannel;
    _moneyChannel = null;
    _subscribedAccount = null;
    if (channel != null && client != null) {
      unawaited(client!.removeChannel(channel));
    }
  }
}
