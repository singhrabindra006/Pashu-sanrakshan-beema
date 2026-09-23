import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { unknown, online, offline }

/// Drives the offline banner. Deliberately separate from request errors: a
/// request can still fail while the device reports a connection.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(ConnectivityStatus.unknown);

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> start() async {
    _emitFor(await _connectivity.checkConnectivity());
    _subscription ??= _connectivity.onConnectivityChanged.listen(_emitFor);
  }

  void _emitFor(List<ConnectivityResult> results) {
    final isOffline = results.isEmpty || results.every((result) => result == ConnectivityResult.none);
    emit(isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
