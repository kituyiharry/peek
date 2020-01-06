import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:yame/models/quote.dart' as Quote;

const int kColorMin = 127;

enum MarketListType { GAINERS, LOSERS, INFOCUS }

class MarketList {
  static final String _sListsEndpoint = '/stock/market/list';
  static final String sListsGainers = '$_sListsEndpoint/gainers';
  static final String sListsLosers = '$_sListsEndpoint/losers';
  static final String sListsInfocus = '$_sListsEndpoint/mostactive';

  final MarketListType _marketListType;
  final Quote.Quote _quote;
  final Color kColora = Color.fromRGBO(
      kColorMin + Math.Random().nextInt(255 - kColorMin),
      kColorMin + Math.Random().nextInt(255 - kColorMin),
      kColorMin + Math.Random().nextInt(255 - kColorMin),
      1.0);
  final Color kColorb = Color.fromRGBO(
      kColorMin + Math.Random().nextInt(255 - kColorMin),
      kColorMin + Math.Random().nextInt(255 - kColorMin),
      kColorMin + Math.Random().nextInt(255 - kColorMin),
      1.0);

  MarketList(this._marketListType, this._quote);

  MarketList.fromJson(Map marketListJson, MarketListType marketListType)
      : _marketListType = marketListType,
        _quote = Quote.Quote.fromJson(marketListJson);
  get quote => this._quote;
  get marketListType => this._marketListType;
}
