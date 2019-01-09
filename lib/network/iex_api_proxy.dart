import 'dart:async';
import 'dart:convert' as Convert;
import 'package:http/http.dart' as Http;
import 'package:peek/models/sectors_model.dart' as Sectors;
import 'package:peek/models/lists.dart' as MarketLists;
import 'package:peek/models/quote.dart' as Quote;
import 'package:peek/models/charts.dart' as Charts;
import 'package:peek/models/company.dart' as Company;
import 'package:peek/models/financials.dart' as Financials;
import 'package:peek/models/stats.dart' as Stats;

class IexApiProxy {
  static final String _sEndpoint = "https://api.iextrading.com/1.0/stock/";
  static IexApiProxy _sIexApiProxyInstance;
  final Http.Client httpClient = Http.Client();

  IexApiProxy() {
    print('Instantiating instance!!');
  }

  static getInstance() {
    if (_sIexApiProxyInstance == null) {
      _sIexApiProxyInstance = IexApiProxy();
    }
    return _sIexApiProxyInstance;
  }

  Future<List<Sectors.SectorModel>> fetchSectors() async {
    List<Sectors.SectorModel> sectors = [];
    await httpClient
        .get(Uri.parse('$_sEndpoint${Sectors.SectorModel.sSectorsEndpoint}'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((sectorsData) => sectorsData.forEach(
            (sector) => sectors.add(Sectors.SectorModel.fromJson(sector))));

    return sectors;
  }

  Future<List<MarketLists.MarketList>> fetchAList(
      MarketLists.MarketListType marketListType) async {
    List<MarketLists.MarketList> list = [];
    String finEndPoint;
    switch (marketListType) {
      case MarketLists.MarketListType.GAINERS:
        finEndPoint = MarketLists.MarketList.sListsGainers;
        break;
      case MarketLists.MarketListType.LOSERS:
        finEndPoint = MarketLists.MarketList.sListsLosers;
        break;
      case MarketLists.MarketListType.INFOCUS:
        finEndPoint = MarketLists.MarketList.sListsInfocus;
        break;
      default:
        finEndPoint = MarketLists.MarketList.sListsInfocus;
        break;
    }

    await httpClient
        .get(Uri.parse('$_sEndpoint$finEndPoint'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((marketsData) => marketsData.forEach((listData) => list
            .add(MarketLists.MarketList.fromJson(listData, marketListType))));

    return list;
  }

  Future<Stats.KeyStats> fetchStatsFor(String symbol) async {
    Stats.KeyStats stats;

    await httpClient
        .get(Uri.parse('$_sEndpoint$symbol${Stats.KeyStats.sEndpoint}'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      try {
        stats = Stats.KeyStats.fromJsonMap(data);
      } catch (e) {
        print("ParseError stats: $e");
      }
    }).catchError((e) {
      print("CatchError stats: $e");
    });
    return stats;
  }

  Future<Charts.ChartModel> fetchChartData(
      String symbol, Charts.ChartDurations duration,
      [int interval]) async {
    Charts.ChartModel chartModel;
    await httpClient
        .get(Uri.parse(
            '$_sEndpoint${Charts.ChartModel.constructEndpoint(symbol, duration, interval)}'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((chartData) {
      chartModel = Charts.ChartModel(symbol, duration, interval, chartData);
    });

    return chartModel;
  }

  Future<Company.CompanyModel> fetchCompanyData(String symbol) async {
    Company.CompanyModel companyModel;
    await httpClient
        .get(Uri.parse('$_sEndpoint$symbol${Company.CompanyModel.sEndpoint}'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      if (data != null) {
        try {
          companyModel = Company.CompanyModel.fromJson(data);
        } catch (e) {
          print("Error: $e");
        }
      }
    });

    return companyModel;
  }

  dispose() {
    _sIexApiProxyInstance = null;
  }

  Future<List<Quote.Quote>> fetchCollectionsFor(String sector) async {
    print("Fetching $sector!");
    List<Quote.Quote> quoteList = [];
    await httpClient
        .get(Uri.parse(
            '${_sEndpoint}market/collection/sector?collectionName=$sector'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      (data as List).forEach((q) {
        if (q != null) {
          Quote.Quote quote;
          try {
            quote = Quote.Quote.fromJson(q);
          } catch (e) {
            print("Error: $e");
          }
          if (quote != null) {
            quoteList.add(quote);
          }
        }
      });
    }).catchError((e) {
      print(e);
    });
    quoteList.sort((qa, qb) => qa.compareTo(qb));
    return quoteList;
  }

  Future<List<Quote.Quote>> batchQuoteProcessor(List<String> symbols) async {
    print("Fetching quotes for ${symbols.join(',')}");
    List<Quote.Quote> quotes = [];

    await httpClient
        .get(Uri.parse(
            '${_sEndpoint}market/batch?symbols=${symbols.join(",")}&types=quote'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      symbols.forEach((sym) {
        Quote.Quote quote;
        try {
          quote = Quote.Quote.fromJson(data[sym]['quote']);
        } catch (e) {
          print(e);
        } finally {
          if (quote != null) {
            quotes.add(quote);
          }
        }
      });
    }).catchError((e) {
      print(e);
    });
    return quotes;
  }

  Future<List<Financials.FinancialsModel>> fetchFinancialsFor(
      String symbol) async {
    // TODO: Support quarterly and annual
    List<Financials.FinancialsModel> financialsModel = [];
    await httpClient
        .get(Uri.parse(
            '$_sEndpoint$symbol${Financials.FinancialsModel.sEndPoint}'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      (data['financials'] as List).forEach((item) {
        if (item != null) {
          Financials.FinancialsModel model;
          try {
            model = Financials.FinancialsModel.fromJsonMap(item);
          } catch (e) {
            print("Error: $e");
          } finally {
            if (model != null) financialsModel.add(model);
          }
        }
        //financialsModel.add(Financials.FinancialsModel.fromJsonMap(item));
      });
    }).catchError((e) {
      print("Catch Error: $e");
    });
    return financialsModel;
  }

  Future<Quote.Quote> fetchSingleQuote(String symbol) async {
    Quote.Quote quote;
    await httpClient
        .get(Uri.parse('$_sEndpoint$symbol/quote'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      try {
        quote = Quote.Quote.fromJson(data);
      } catch (e) {
        print(e);
      }
    }).catchError((e) {
      print(e);
    });
    return quote;
  }

  Future<List<Quote.Quote>> batchPeerProcessor(String symbol) async {
    List<String> _peerList = [];
    List<Quote.Quote> quotes = [];
    await httpClient
        .get(Uri.parse('$_sEndpoint/$symbol/relevant'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      (data["symbols"] as List).forEach((i) {
        _peerList.add(i.toString());
        //peerList = data as List<String>;
      });
    });

    await httpClient
        .get(Uri.parse(
            '${_sEndpoint}market/batch?symbols=${_peerList.join(",")}&types=quote'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      _peerList.forEach((sym) {
        Quote.Quote quote;
        try {
          quote = Quote.Quote.fromJson(data[sym]['quote']);
        } catch (e) {
          print(e);
        } finally {
          if (quote != null) {
            quotes.add(quote);
          }
        }
      });
    }).catchError((e) {
      print(e);
    });

    return quotes;
  }

  Future<List<String>> fetchPeers(String symbol) async {
    List<String> peerList = [];
    await httpClient
        .get(Uri.parse('$_sEndpoint/$symbol/peers'))
        .then((response) => response.body)
        .then(Convert.json.decode)
        .then((data) {
      (data as List).forEach((i) {
        peerList.add(i.toString());
      });
      //peerList = data as List<String>;
    });
    return peerList;
  }
}
