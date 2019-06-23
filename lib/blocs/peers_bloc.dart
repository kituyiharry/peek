import 'dart:async';

import 'package:yame/network/iex_api_proxy.dart' as IEX;
import 'package:yame/models/quote.dart';

class PeersBloc {
  final IEX.IexApiProxy _iexApiProxy;
  final String symbol;
  Stream<List<Quote>> peerStream = Stream.empty();

  PeersBloc(this._iexApiProxy, this.symbol) {
    peerStream = _iexApiProxy.batchPeerProcessor(symbol).asStream();
  }

  void refresh() {
    peerStream = Stream.empty();
    peerStream = _iexApiProxy.batchPeerProcessor(symbol).asStream();
  }
}
