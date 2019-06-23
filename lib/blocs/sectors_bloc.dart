import 'dart:async';

import 'package:yame/models/sectors_model.dart' as Sectors;
import 'package:yame/network/iex_api_proxy.dart' as IEX;

class SectorBloc {
  final IEX.IexApiProxy _iexApiProxy;
  Stream<List<Sectors.SectorModel>> _sectorStream = Stream.empty();
  Stream<List<Sectors.SectorModel>> get sectorStream => _sectorStream;

  SectorBloc(this._iexApiProxy) {
    _sectorStream = this._iexApiProxy.fetchSectors().asStream();
  }

  void refresh() {
    _sectorStream = Stream.empty();
    _sectorStream = this._iexApiProxy.fetchSectors().asStream();
  }
}
