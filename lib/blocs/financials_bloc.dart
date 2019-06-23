import 'dart:async';

import 'package:yame/network/iex_api_proxy.dart';
import 'package:yame/models/financials.dart';

class FinancialsBloc {
  final IexApiProxy _iexApiProxy;
  final String symbol;
  Stream<List<FinancialsModel>> financialsStream = Stream.empty();
  FinancialsBloc(this._iexApiProxy, this.symbol)
      : financialsStream = _iexApiProxy.fetchFinancialsFor(symbol).asStream();

  void refresh() {
    financialsStream = Stream.empty();
    financialsStream = _iexApiProxy.fetchFinancialsFor(symbol).asStream();
  }
}
