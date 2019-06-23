import 'dart:async';

import 'package:yame/models/company.dart';
import 'package:yame/network/iex_api_proxy.dart';

class CompanyBloc {
  final IexApiProxy _iexApiProxy;
  final String symbol;
  Stream<CompanyModel> infoStream = Stream.empty();

  CompanyBloc(this._iexApiProxy, this.symbol) {
    infoStream = _iexApiProxy.fetchCompanyData(symbol).asStream();
  }

  void refresh() {
    infoStream = Stream.empty();
    infoStream = _iexApiProxy.fetchCompanyData(symbol).asStream();
  }
}
