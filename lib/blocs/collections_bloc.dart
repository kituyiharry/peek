import 'dart:async';

import 'package:yame/network/iex_api_proxy.dart' as IEX;
import 'package:yame/models/quote.dart';

class CollectionsBloc {
  final IEX.IexApiProxy _iexApiProxy;
  final String _sector;
  Stream<List<Quote>> _collectionStream = Stream.empty();
  Stream<List<Quote>> get collectionStream => _collectionStream;

  CollectionsBloc(this._iexApiProxy, this._sector) {
    _collectionStream = _iexApiProxy
        .fetchCollectionsFor(_sector)
        .asStream()
        .asBroadcastStream();
  }

  void refresh() {
    _collectionStream = Stream.empty();
    _collectionStream = _iexApiProxy.fetchCollectionsFor(_sector).asStream();
  }
}
