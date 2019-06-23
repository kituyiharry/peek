import 'dart:async';

import 'package:yame/models/lists.dart' as Lists;
import 'package:yame/network/iex_api_proxy.dart' as IEX;

class ListsBloc {
  final IEX.IexApiProxy _iexApiProxy;
  Stream<List<Lists.MarketList>> _gainersListStream = Stream.empty();
  Stream<List<Lists.MarketList>> get gainersListStream => _gainersListStream;

  ListsBloc(this._iexApiProxy) {
    _gainersListStream =
        _iexApiProxy.fetchAList(Lists.MarketListType.GAINERS).asStream();
  }

  void refresh() {
    _gainersListStream = Stream.empty();
    _gainersListStream =
        _iexApiProxy.fetchAList(Lists.MarketListType.GAINERS).asStream();
  }
}

class InfocusListBloc {
  final IEX.IexApiProxy _iexApiProxy;
  Stream<List<Lists.MarketList>> _infocusListStream = Stream.empty();
  Stream<List<Lists.MarketList>> get infocusListStream => _infocusListStream;

  InfocusListBloc(this._iexApiProxy) {
    _infocusListStream =
        _iexApiProxy.fetchAList(Lists.MarketListType.INFOCUS).asStream();
  }

  void refresh() {
    _infocusListStream = Stream.empty();
    _infocusListStream =
        _iexApiProxy.fetchAList(Lists.MarketListType.INFOCUS).asStream();
  }
}

class LosersListBloc {
  final IEX.IexApiProxy _iexApiProxy;
  Stream<List<Lists.MarketList>> _losersListStream = Stream.empty();
  Stream<List<Lists.MarketList>> get losersListStream => _losersListStream;
  LosersListBloc(this._iexApiProxy) {
    _losersListStream =
        _iexApiProxy.fetchAList(Lists.MarketListType.LOSERS).asStream();
  }

  void refresh() {
    _losersListStream = Stream.empty();
    _losersListStream =
        _iexApiProxy.fetchAList(Lists.MarketListType.LOSERS).asStream();
  }
}
