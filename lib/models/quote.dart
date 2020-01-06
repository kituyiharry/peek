import 'package:flutter/material.dart';
import 'dart:math' as Math;

const int kColorMin = 127;

class Quote implements Comparable<Quote> {
  final String symbol;
  final String companyName;
  final String primaryExchange;
  final String sector;
  final String latestSource;
  final dynamic change;
  final dynamic changePercent;
  final dynamic ytdChange;
  final dynamic marketCap;
  final dynamic peRatio;
  final dynamic latestPrice;
  final dynamic delayedPrice;
  final dynamic avgTotalVolume;
  final dynamic open;
  //final DateTime openTime;
  final dynamic close;
  //final DateTime closeTime;
  final String latestTime;
  final dynamic high;
  final dynamic low;
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

  Quote(
      this.symbol,
      this.companyName,
      this.delayedPrice,
      this.primaryExchange,
      this.sector,
      this.latestPrice,
      this.latestTime,
      this.change,
      this.ytdChange,
      this.marketCap,
      this.peRatio,
      this.changePercent,
      this.avgTotalVolume,
      this.open,
      //this.openTime,
      this.close,
      //this.closeTime,
      this.high,
      this.low,
      this.latestSource);

  Quote.fromJson(Map quoteJsonData)
      : symbol = quoteJsonData['symbol'],
        companyName = quoteJsonData['companyName'],
        latestSource = quoteJsonData['latestSource'],
        latestPrice = quoteJsonData['latestPrice'],
        delayedPrice = quoteJsonData['delayedPrice'],
        primaryExchange = quoteJsonData['primaryExchange'],
        sector = quoteJsonData['sector'],
        ytdChange = quoteJsonData['ytdChange'],
        marketCap = quoteJsonData['marketCap'],
        peRatio = quoteJsonData['peRatio'],
        latestTime = quoteJsonData['latestTime'],
        change = quoteJsonData['change'],
        changePercent = quoteJsonData['changePercent'],
        avgTotalVolume = quoteJsonData['avgTotalVolume'],
        open = quoteJsonData['open'],
        //openTime = DateTime.parse(quoteJsonData['closeTime']),
        close = quoteJsonData['close'],
        //closeTime = DateTime.parse(quoteJsonData['closeTime']),
        high = quoteJsonData['high'],
        low = quoteJsonData['low'];

  @override
  int compareTo(Quote other) {
    // TODO: implement compareTo
    return this.symbol.compareTo(other.symbol);
  }
}
