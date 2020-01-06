import 'dart:async';
import 'dart:ui';
import 'dart:convert';
//import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/gestures.dart';
import 'package:yame/models/company.dart';
//import 'package:transparent_image/transparent_image.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_candlesticks/flutter_candlesticks.dart';
import 'package:shared_preferences/shared_preferences.dart';

//import 'package:intl/intl.dart';
//import 'package:flutter_range_slider/flutter_range_slider.dart';

import 'package:yame/models/sectors_model.dart';
import 'package:yame/models/lists.dart';
import 'package:yame/models/quote.dart';
import 'package:yame/models/charts.dart';
//import 'package:yame/models/stats.dart';
import 'package:yame/models/financials.dart';

import 'package:yame/blocs/sectors_bloc.dart';
import 'package:yame/blocs/lists_bloc.dart';
import 'package:yame/blocs/peers_bloc.dart';
import 'package:yame/blocs/collections_bloc.dart';
import 'package:yame/blocs/charts_bloc.dart';
import 'package:yame/blocs/company_info_bloc.dart';
import 'package:yame/blocs/stats_bloc.dart';
import 'package:yame/blocs/financials_bloc.dart';

import 'package:yame/providers/iex_api_provider.dart';
import 'package:yame/network/iex_api_proxy.dart';
//import 'package:yame/network/unsplash_api_proxy.dart';

const double kOverlayBoxWidth = 160.0;
const double kOverlayBoxHeight = 160.0;
const double kOverlayCardWidth = 296.0;
const int kColorMin = 127;
void main() => runApp(ValuePeekApp());

class ValuePeekApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IexApiProvider(
      sBloc: SectorBloc(IexApiProxy.getInstance()),
      child: MaterialApp(
          title: "Yame",
          routes: {
            //'/': (c) => ValuePeekHome(),
            '/sector': (_) => SectorInformation('Energy', 0.0)
          },
          theme: ThemeData(
              fontFamily: 'Montserrat',
              primaryColor: Color(0xFF529C82),
              iconTheme: IconThemeData(color: Colors.white),
              accentColor: Color(0xFFed8d8d),
              backgroundColor: Color(0xFF529C82),
              secondaryHeaderColor: Color(0xFF4d4545)),
          home: SplashPage()),
    );
  }
}

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => new _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Future<bool> _getAgreedState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAgreedPref') ?? false;
  }

  @override
  void initState() {
    super.initState();
    _getAgreedState().then((value) {
      print(value);
      if (value) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => ValuePeekHome()));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AttributionPage()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ValuePeekHome extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ValuePeekHomeState();
  }
}

class ValuePeekHomeState extends State<ValuePeekHome>
    with TickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();
  Future searchAssets;
  IexApiProxy proxy;
  TextEditingController _editingController;
  FocusNode _editFocusNode = FocusNode();

  Stream<List<dynamic>> searchItems = Stream.empty();
  Stream<String> _log = Stream.empty();
  Stream<Quote> _searchQuoteStream = Stream.empty();

  ReplaySubject<String> _query = ReplaySubject<String>(maxSize: 10);
  ReplaySubject<String> _quote = ReplaySubject<String>(maxSize: 1);
  Sink<String> get query => _query;
  List<dynamic> searchData;

  @override
  void initState() {
    super.initState();
    proxy = IexApiProxy.getInstance();
    searchAssets =
        DefaultAssetBundle.of(context).loadString("assets/json/symbols.json");
    searchItems = _query
        .distinct()
        .debounce(Duration(milliseconds: 500))
        .asyncMap(searchClues)
        .asBroadcastStream();
    _log = Observable(searchItems)
        .withLatestFrom(_query.stream, (_, query) => "Results for: $query")
        .asBroadcastStream();
    searchAssets.then((d) {
      searchData = json.decode(d);
    });
  }

  List<dynamic> searchClues(String clue) {
    return searchData
        .where((d) => (d['symbol'].toString().contains(clue.toUpperCase()) ||
            d['name'].toString().toLowerCase().contains(clue.toLowerCase())))
        .take(10)
        .toList();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _query.close();
    _quote.close();
    _editFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SectorBloc sectorBloc = IexApiProvider.sectorBlocOf(context);
    final ListsBloc listsBloc = IexApiProvider.listsBlocOf(context);
    final LosersListBloc losersListBloc =
        IexApiProvider.losersListBlocOf(context);
    final InfocusListBloc infocusListBloc =
        IexApiProvider.infocusListBlocOf(context);

    return Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
        floatingActionButton: FloatingActionButton(
            child: Icon(Icons.arrow_upward),
            onPressed: () {
              scrollController.animateTo(0.0,
                  duration: Duration(milliseconds: 600), curve: Curves.easeIn);
            }),
        body: NestedScrollView(
          physics: BouncingScrollPhysics(),
          controller: scrollController,
          headerSliverBuilder: (ctx, _scr) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                title: const Text(
                  'YAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Pacifico',
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // primary: true,
                centerTitle: true,
                expandedHeight: 56.0,
                backgroundColor: Colors.transparent,
                elevation: 0.0,
              ),
            ];
          },
          body: Builder(
            builder: (con) => RefreshIndicator(
                  displacement: 100.0,
                  onRefresh: () {
                    setState(() {
                      sectorBloc.refresh();
                      listsBloc.refresh();
                      losersListBloc.refresh();
                      infocusListBloc.refresh();
                    });
                    return Future.delayed(Duration(milliseconds: 100));
                  },
                  child: CustomScrollView(
                    physics: BouncingScrollPhysics(),
                    slivers: <Widget>[
                      SliverToBoxAdapter(
                          child: Container(
                        child: Column(
                          children: <Widget>[
                            StreamBuilder(
                              builder: (c, snapshot) {
                                return Container(
                                  height: 30.0,
                                  child: Text(
                                    snapshot?.data ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                              stream: _log,
                            ),
                            Container(
                              child: StreamBuilder(
                                builder: (c, snapshot) {
                                  return AnimatedCrossFade(
                                    firstChild: Container(
                                      height: 140.0,
                                      margin: EdgeInsets.only(bottom: 8.0),
                                      child: const Center(
                                          child:
                                              const CircularProgressIndicator()),
                                    ),
                                    secondChild: (snapshot.hasData)
                                        ? Container(
                                            height: 140,
                                            margin:
                                                EdgeInsets.only(bottom: 8.0),
                                            alignment: Alignment.center,
                                            child: GradientColorCard(
                                              child: QuoteWidget(
                                                allowPushRoute: true,
                                                index: snapshot.data,
                                                focusNode: _editFocusNode,
                                                ifIsCrypto: Scaffold.of(con),
                                                isCrypto:
                                                    (snapshot.data as Quote)
                                                            .sector ==
                                                        "cryptocurrency",
                                              ),
                                              kColora: snapshot.data.kColora,
                                              kColorb: snapshot.data.kColorb,
                                            ),
                                          )
                                        : Container(
                                            /*height: 140,child: Center(child: CircularProgressIndicator(),),*/),
                                    crossFadeState: (snapshot.connectionState !=
                                            ConnectionState.done)
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    duration: Duration(milliseconds: 200),
                                    firstCurve: Curves.easeIn,
                                    secondCurve: Curves.easeIn,
                                  );
                                },
                                stream: _searchQuoteStream,
                              ),
                            ),
                            Container(
                                height: 60,
                                child: StreamBuilder(
                                  builder: (_, snapshot) {
                                    if (snapshot.hasData) {
                                      if (snapshot.data.length != 1) {
                                        return ListView.builder(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          scrollDirection: Axis.horizontal,
                                          itemCount: snapshot.data.length,
                                          itemBuilder: (ctx, index) {
                                            var indexedItem = snapshot.data[
                                                index % snapshot.data.length];
                                            return Material(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                child: InkWell(
                                                    onTap: () {
                                                      _searchQuoteStream =
                                                          Stream.empty();
                                                      setState(() {
                                                        _searchQuoteStream = proxy
                                                            .fetchSingleQuote(
                                                                indexedItem[
                                                                    'symbol'])
                                                            .asStream();
                                                      });
                                                    },
                                                    child: Container(
                                                        width:
                                                            kOverlayBoxWidth +
                                                                30,
                                                        padding:
                                                            EdgeInsets.all(2.0),
                                                        margin: const EdgeInsets
                                                                .symmetric(
                                                            vertical: 8.0,
                                                            horizontal: 4.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .accentColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          boxShadow: [
                                                            BoxShadow(
                                                                color: const Color
                                                                        .fromRGBO(
                                                                    0,
                                                                    0,
                                                                    0,
                                                                    0.25),
                                                                blurRadius:
                                                                    6.0),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          //crossAxisAlignment: CrossAxisAlignment.stretch,
                                                          children: <Widget>[
                                                            Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            4.0)),
                                                            Container(
                                                                width: 32.0,
                                                                height: 32.0,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  //color: Colors.white70
                                                                ),
                                                                //radius: 16.0,
                                                                child:
                                                                    CustomCircleAvatar(
                                                                  myImage:
                                                                      NetworkImage(
                                                                    "https://storage.googleapis.com/iex/api/logos/${indexedItem['symbol']}.png",
                                                                  ),
                                                                  initials: indexedItem[
                                                                          'symbol']
                                                                      .toString()
                                                                      .split('')
                                                                      .first,
                                                                )),
                                                            Spacer(),
                                                            Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: <
                                                                  Widget>[
                                                                Container(
                                                                  width: 120,
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Text(
                                                                    indexedItem[
                                                                        'name'],
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black87,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: Text(
                                                                      indexedItem[
                                                                          'symbol'],
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black87,
                                                                          fontStyle:
                                                                              FontStyle.italic),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    )),
                                                              ],
                                                            )
                                                          ],
                                                        ))));
                                          },
                                        );
                                      } else {
                                        var indexedItem = snapshot.data[0];
                                        return Center(
                                            child: Material(
                                                color: Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(4.0),
                                                child: InkWell(
                                                    onTap: () {
                                                      _searchQuoteStream =
                                                          Stream.empty();
                                                      setState(() {
                                                        _searchQuoteStream = proxy
                                                            .fetchSingleQuote(
                                                                indexedItem[
                                                                    'symbol'])
                                                            .asStream();
                                                      });
                                                    },
                                                    child: Container(
                                                        width:
                                                            kOverlayBoxWidth +
                                                                30,
                                                        padding:
                                                            EdgeInsets.all(4.0),
                                                        margin: const EdgeInsets
                                                            .all(4.0),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Theme.of(context)
                                                                  .accentColor,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                          boxShadow: [
                                                            BoxShadow(
                                                                color: const Color
                                                                        .fromRGBO(
                                                                    0,
                                                                    0,
                                                                    0,
                                                                    0.25),
                                                                blurRadius:
                                                                    6.0),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          //crossAxisAlignment: CrossAxisAlignment.stretch,
                                                          children: <Widget>[
                                                            Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            4.0)),
                                                            Container(
                                                                width: 32.0,
                                                                height: 32.0,
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  //color: Colors.white70
                                                                ),
                                                                //radius: 16.0,
                                                                child:
                                                                    CustomCircleAvatar(
                                                                  myImage:
                                                                      NetworkImage(
                                                                    "https://storage.googleapis.com/iex/api/logos/${indexedItem['symbol']}.png",
                                                                  ),
                                                                  initials: indexedItem[
                                                                          'symbol']
                                                                      .toString()
                                                                      .split('')
                                                                      .first,
                                                                )),
                                                            Spacer(),
                                                            Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: <
                                                                  Widget>[
                                                                Container(
                                                                  width: 120,
                                                                  alignment:
                                                                      Alignment
                                                                          .centerLeft,
                                                                  child: Text(
                                                                    indexedItem[
                                                                        'name'],
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .black87,
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                                Container(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: Text(
                                                                      indexedItem[
                                                                          'symbol'],
                                                                      style: TextStyle(
                                                                          color: Colors
                                                                              .black87,
                                                                          fontStyle:
                                                                              FontStyle.italic),
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    )),
                                                              ],
                                                            )
                                                          ],
                                                        )))));
                                      }
                                    } else {
                                      return Center(
                                          child: Text(
                                        "Type to search",
                                        style: TextStyle(color: Colors.white),
                                        overflow: TextOverflow.ellipsis,
                                      ));
                                    }
                                  },
                                  stream: searchItems,
                                )),
                          ],
                        ),
                      )),
                      SliverAppBar(
                        floating: true,
                        primary: true,
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                        elevation: 0.0,
                        flexibleSpace: SafeArea(
                            child: Row(children: [
                          Expanded(
                            child: Container(
                                margin: const EdgeInsets.fromLTRB(
                                    16.0, 8.0, 16.0, 4.0),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(48.0)),
                                child: FutureBuilder(
                                  builder: (_, d) {
                                    return TextField(
                                      controller: _editingController,
                                      focusNode: _editFocusNode,
                                      textInputAction: TextInputAction.search,
                                      enabled: d.hasData,
                                      onChanged: (s) {
                                        if (s.isNotEmpty) query.add(s);
                                      },
                                      decoration: InputDecoration(
                                        hintText:
                                            "Search tickers, exchanges and companies",
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.all(16.0),
                                        //fillColor: Colors.white.withOpacity(0.8),
                                        prefixIcon: d.hasData
                                            ? Icon(Icons.search)
                                            : Icon(Icons.sync),
                                      ),
                                    );
                                  },
                                  future: searchAssets,
                                  initialData: false,
                                )),
                          ),
                        ])),
                        //elevation: 0.0,
                      ),
                      SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 8.0)),
                      _titleSliverBoxSection("Gainers", "Top  biggest gainers"),
                      _streamHandlerSliverBoxSection(
                          listsBloc.gainersListStream, (AsyncSnapshot data) {
                        return _marketListBuilder(
                            data.data as List<MarketList>, con);
                      }),
                      SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 8.0)),
                      _titleSliverBoxSection(
                          "Losers", "Markets biggest losers!"),
                      _streamHandlerSliverBoxSection(
                          losersListBloc.losersListStream,
                          (AsyncSnapshot data) {
                        return _marketListBuilder(
                            data.data as List<MarketList>, con);
                      }),
                      SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 8.0)),
                      _titleSliverBoxSection(
                          "In Focus", "Items identified as infocus"),
                      _streamHandlerSliverBoxSection(
                          infocusListBloc.infocusListStream,
                          (AsyncSnapshot data) {
                        return _marketListBuilder(
                            data.data as List<MarketList>, con);
                      }),
                      SliverPadding(
                          padding: EdgeInsets.symmetric(vertical: 8.0)),
                      _titleSliverBoxSection("Sectors",
                          "Performance is based on each sector ETF."),
                      _streamHandlerSliverBoxSection(sectorBloc.sectorStream,
                          (AsyncSnapshot data) {
                        return sectorsListViewBuilder(
                            data.data as List<SectorModel>);
                      }),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(vertical: 48.0),
                        sliver: SliverToBoxAdapter(
                          child: Center(
                            child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.all(4.0),
                                child: AttributionWidget()),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
          ),
        ));
  }

  Widget _streamHandlerSliverBoxSection(
      Stream sectionStream, Function onDataAvailable) {
    return SliverToBoxAdapter(
      child: Container(
          //color: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.transparent,
          ),
          height: kOverlayBoxHeight + 4.0,
          //margin: EdgeInsets.only(bottom: 50.0),
          child: StreamBuilder(
              stream: sectionStream,
              builder: (context, snapshot) {
                return AnimatedCrossFade(
                    firstCurve: Curves.fastOutSlowIn,
                    secondCurve: Curves.fastOutSlowIn,
                    sizeCurve: Curves.easeIn,
                    // alignment: Alignment.bottomCenter,
                    firstChild:
                        (snapshot.connectionState == ConnectionState.none)
                            ? const Center(
                                child: const Icon(
                                Icons.cloud_off,
                                color: Colors.white,
                                size: 32.0,
                              ))
                            : const Center(
                                child: const CircularProgressIndicator()),
                    secondChild: (!snapshot.hasData
                        ? Center(
                            child: const Icon(
                            Icons.cloud_off,
                            color: Colors.white,
                            size: 32.0,
                          ))
                        : onDataAvailable(snapshot)),
                    crossFadeState:
                        (snapshot.connectionState != ConnectionState.done)
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                    duration: Duration(milliseconds: 900));
              })),
    );
  }

  Widget _titleSliverBoxSection(
    String title,
    String description,
  ) {
    return SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        sliver: SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            height: 80.0,
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28.0),
                ),
                const Divider(
                  color: Colors.white70,
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.white, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ));
  }

  Widget sectorsListViewBuilder(List<SectorModel> data) {
    return ListView.builder(
      itemBuilder: (BuildContext c, int i) {
        SectorModel index = data[i];
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (c) =>
                      SectorInformation(index.name, index.performance)));
            },
            child: Stack(children: [
              Container(
                width: kOverlayBoxWidth,
                margin:
                    const EdgeInsets.only(right: 8.0, bottom: 4.0, top: 4.0),
                decoration: BoxDecoration(
                    color: Theme.of(context).accentColor,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                          color: const Color.fromRGBO(0, 0, 0, 0.25),
                          blurRadius: 6.0),
                    ],
                    image: DecorationImage(
                        image: NetworkImage(
                            "https://source.unsplash.com/200x200/?${index.name}"),
                        alignment: Alignment.center,
                        fit: BoxFit.cover)),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                        color:
                            index.performance < 0 ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4.0)),
                    child: Text(
                      "${(index.performance * 100).toStringAsFixed(2)}%",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                          fontSize: 20.0),
                    ),
                  ),
                ),
              ),
              Positioned(
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0)),
                      color: Colors.white.withOpacity(0.7)),
                  width: kOverlayBoxWidth,
                  height: 40.0,
                  child: Text(
                    "${index.name}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                bottom: 4.0,
              )
            ]),
          ),
        );
      },
      itemCount: data.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 40.0),
      scrollDirection: Axis.horizontal,
    );
  }

  Widget _marketListBuilder(List<MarketList> gainList, BuildContext con) {
    return ListView.builder(
      itemCount: gainList.length,
      itemBuilder: (BuildContext c, int i) {
        Quote index = (gainList[i].quote as Quote);
        return GradientColorCard(
            kColora: gainList[i].kColora,
            kColorb: gainList[i].kColorb,
            child: QuoteWidget(
              index: index,
              allowPushRoute: true,
              focusNode: _editFocusNode,
              isCrypto: index.sector == "cryptocurrency",
              ifIsCrypto: Scaffold.of(con),
            ));
      },
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 40.0),
      scrollDirection: Axis.horizontal,
    );
  }

  String sourceToSimpleString(String src) {
    if (src.contains('Close')) {
      return src;
    } else if (src.contains('IEX')) {
      return "by IEX";
    } else if (src.contains('15')) {
      return "15 min";
    } else {
      return "Previous";
    }
  }

  String numToSimple(dynamic num) {
    if (num == null) {
      return "N/A";
    }
    if (num > 1000000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} T";
    } else if (num > 1000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} B";
    } else if (num > 1000000) {
      return "${((num / 1000000) as double).toStringAsFixed(2)} M";
    } else if (num > 1000) {
      return "${((num / 1000) as double).toStringAsFixed(2)} K";
    } else {
      if (num is int) {
        return num.toDouble().toStringAsFixed(2);
      }
      return (num as double)?.toStringAsFixed(2);
    }
  }
}

class SliverObstructionInjector extends SliverOverlapInjector {
  /// Creates a sliver that is as tall as the value of the given [handle]'s
  /// layout extent.
  ///
  /// The [handle] must not be null.
  const SliverObstructionInjector({
    Key key,
    @required SliverOverlapAbsorberHandle handle,
    Widget child,
  })  : assert(handle != null),
        super(key: key, handle: handle, sliver: child);

  @override
  RenderSliverObstructionInjector createRenderObject(BuildContext context) {
    return new RenderSliverObstructionInjector(
      handle: handle,
    );
  }
}

// Helper utilities for sliveroverlapinjector customized specifically for this layout,
// Perhaps it isn't needed but is around for now in case i need to support sticky headers

/// A sliver that has a sliver geometry based on the values stored in a
/// [SliverOverlapAbsorberHandle].
///
/// The [RenderSliverOverlapAbsorber] must be an earlier descendant of a common
/// ancestor [RenderViewport] (probably a [RenderNestedScrollViewViewport]), so
/// that it will always be laid out before the [RenderSliverObstructionInjector]
/// during a particular frame.
class RenderSliverObstructionInjector extends RenderSliverOverlapInjector {
  /// Creates a sliver that is as tall as the value of the given [handle]'s extent.
  ///
  /// The [handle] must not be null.
  RenderSliverObstructionInjector({
    @required SliverOverlapAbsorberHandle handle,
    RenderSliver child,
  })  : assert(handle != null),
        _handle = handle,
        super(handle: handle);

  double _currentLayoutExtent;
  double _currentMaxExtent;

  /// The object that specifies how wide to make the gap injected by this render
  /// object.
  ///
  /// This should be a handle owned by a [RenderSliverOverlapAbsorber] and a
  /// [RenderNestedScrollViewViewport].
  SliverOverlapAbsorberHandle get handle => _handle;
  SliverOverlapAbsorberHandle _handle;
  set handle(SliverOverlapAbsorberHandle value) {
    assert(value != null);
    if (handle == value) return;
    if (attached) {
      handle.removeListener(markNeedsLayout);
    }
    _handle = value;
    if (attached) {
      handle.addListener(markNeedsLayout);
      if (handle.layoutExtent != _currentLayoutExtent ||
          handle.scrollExtent != _currentMaxExtent) markNeedsLayout();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    handle.addListener(markNeedsLayout);
    if (handle.layoutExtent != _currentLayoutExtent ||
        handle.scrollExtent != _currentMaxExtent) markNeedsLayout();
  }

  @override
  void performLayout() {
    _currentLayoutExtent = handle.layoutExtent;
    _currentMaxExtent = handle.layoutExtent;
    // print(
    //   'clamped: $_currentLayoutExtent, min($diff, ${constraints.remainingPaintExtent}), viewport:  ${constraints.viewportMainAxisExtent} ');
    //
    //

    //print(
    //   'offset: ${constraints.scrollOffset}, min($diff, ${constraints.remainingPaintExtent}), viewport:  ${constraints.viewportMainAxisExtent} ');
    geometry = new SliverGeometry(
      // scrollExtent:0.0,
      // paintExtent: math.max(0.0, clampedLayoutExtent),
      //maxPaintExtent: _currentMaxExtent,

      scrollExtent: 0.0,
      // paintExtent: math.max(0.0, diff),
      //layoutExtent: _currentMaxExtent,

      paintExtent: _currentMaxExtent,
      maxPaintExtent: _currentMaxExtent,
    );
  }
}

class GradientColorCard extends StatelessWidget {
  final QuoteWidget child;
  final Color kColora;
  final Color kColorb;

  GradientColorCard({this.child, this.kColora, this.kColorb});

  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: child.index.symbol,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: kOverlayBoxHeight,
            minWidth: kOverlayBoxWidth,
          ),
          child: Container(
            width: kOverlayCardWidth,
            margin: EdgeInsets.only(right: 8.0, bottom: 4.0, top: 4.0),
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [kColora, kColorb],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.35), blurRadius: 8.0),
              ],
            ),
            child: child,
          ),
        ));
  }
}

class CustomCircleAvatar extends StatefulWidget {
  final NetworkImage myImage;
  final String initials;

  CustomCircleAvatar({this.myImage, this.initials});

  @override
  _CustomCircleAvatarState createState() => new _CustomCircleAvatarState();
}

class _CustomCircleAvatarState extends State<CustomCircleAvatar> {
  bool _checkLoading = true;

  @override
  void initState() {
    super.initState();
    widget.myImage.resolve(new ImageConfiguration()).addListener(
        ImageStreamListener((_, __) {
          if (mounted) {
            setState(() {
              _checkLoading = false;
            });
          }
        })
        /*
    */
    );

  }

  @override
  Widget build(BuildContext context) {
    return _checkLoading == true
        ? new CircleAvatar(child: new Text(widget.initials))
        : new Container(
            decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                image: DecorationImage(
                    image: widget.myImage,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    repeat: ImageRepeat.noRepeat)),
          );
  }
}

class SectorInformation extends StatefulWidget {
  final String sector;
  final dynamic perf;

  SectorInformation(this.sector, this.perf);

  @override
  _SectorInformationState createState() => _SectorInformationState();
}

class _SectorInformationState extends State<SectorInformation> {
  ScrollController _scrollController;
  CollectionsBloc _collectionsBloc;

  @override
  void initState() {
    super.initState();
    _collectionsBloc =
        CollectionsBloc(IexApiProxy.getInstance(), widget.sector);
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_scrollController.hasClients) _scrollController.jumpTo(0);
        },
        child: Icon(Icons.arrow_drop_up),
      ),
      body:
          /*NestedScrollView(
          //controller: _scrollController,
          headerSliverBuilder: (c, b) => [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  title: Text(
                    widget.sector,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: Colors.white,
                      //letterSpacing: 4.0,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // primary: true,
                  centerTitle: true,
                  expandedHeight: 56.0,
                  backgroundColor: Colors.transparent,
                  elevation: 0.0,
                ),
              ],
          body: */

          SafeArea(
        child: StreamBuilder(
            stream: _collectionsBloc.collectionStream,
            //initialData: [],
            builder: (b, snapshot) {
              return AnimatedCrossFade(
                  firstCurve: Curves.fastOutSlowIn,
                  secondCurve: Curves.fastOutSlowIn,
                  firstChild: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.0),
                          child:
                              (snapshot.connectionState == ConnectionState.none)
                                  ? IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _collectionsBloc.refresh();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.cloud_off,
                                        size: 32.0,
                                        color: Colors.white70,
                                      ),
                                    )
                                  : const Center(
                                      child: const CircularProgressIndicator()),
                        )
                      ]),
                  secondChild: (snapshot.hasData
                      ? CustomScrollView(
                          controller: _scrollController,
                          physics: BouncingScrollPhysics(),
                          slivers: <Widget>[
                            SliverToBoxAdapter(
                              //automaticallyImplyLeading: false,
                              //expandedHeight: 200.0,
                              child: Container(
                                  height: 130,
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 32.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.max,
                                          children: <Widget>[
                                            Text(
                                              "${numToSimple(snapshot.data.length)} Quotes",
                                              style: TextStyle(
                                                  fontSize: 32.0,
                                                  fontWeight: FontWeight.w300,
                                                  color: Colors.white),
                                            ),
                                            FlatButton.icon(
                                              onPressed: () {
                                                setState(() {
                                                  _collectionsBloc.refresh();
                                                });
                                              },
                                              icon: Icon(
                                                Icons.refresh,
                                                size: 20.0,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                "Refresh",
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 32.0),
                                          child: Center(
                                            child: Text(
                                              widget.sector,
                                              style: TextStyle(
                                                  fontSize: 24.0,
                                                  color: Colors.white),
                                            ),
                                          )),
                                      Divider(
                                        color: Colors.white,
                                      ),
                                    ],
                                  )),
                            ),
                            SliverPadding(
                                padding: EdgeInsets.symmetric(vertical: 8)),
                            SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((c, i) {
                                  Quote q = snapshot.data[i] as Quote;
                                  return Center(
                                      child: Dismissible(
                                          key: Key(q.symbol),
                                          dismissThresholds: <DismissDirection,
                                              double>{
                                            DismissDirection.horizontal: 70.0,
                                          },
                                          onDismissed: (d) {
                                            setState(() {
                                              (snapshot.data as List)
                                                  .removeAt(i);
                                            });
                                          },
                                          child: GradientColorCard(
                                            kColora: q.kColora,
                                            kColorb: q.kColorb,
                                            child: QuoteWidget(
                                              index: q,
                                              allowPushRoute: true,
                                              isCrypto:
                                                  q.sector == "cryptocurrency",
                                              ifIsCrypto: Scaffold.of(b),
                                            ),
                                          )));
                                }, childCount: snapshot.data.length),
                              ),
                            )
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              const Icon(
                                Icons.cloud_off,
                                color: Colors.white70,
                                size: 32.0,
                              ),
                              Container(
                                padding: EdgeInsets.all(8.0),
                                child: (snapshot.hasError)
                                    ? Text(
                                        "Data retrieval error",
                                        textAlign: TextAlign.center,
                                      )
                                    : const Center(
                                        child: Text("Connection problems")),
                              )
                            ])),
                  crossFadeState:
                      (snapshot.connectionState != ConnectionState.done)
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                  duration: Duration(milliseconds: 800));
            }),
      ),
    );
  }

  String numToSimple(dynamic num) {
    if (num == null || num is String) {
      return "N/A";
    }
    if (num > 1000000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} T";
    } else if (num > 1000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} B";
    } else if (num > 1000000) {
      return "${((num / 1000000) as double).toStringAsFixed(2)} M";
    } else if (num > 1000) {
      return "${((num / 1000) as double).toStringAsFixed(2)} K";
    } else {
      if (num is int) {
        return num.toString();
      }
      return (num as double)?.toStringAsFixed(2);
    }
  }
}

class QuoteWidget extends StatelessWidget {
  final Quote index;
  final FocusNode focusNode;
  final bool allowPushRoute;
  final bool isCrypto;
  final ScaffoldState ifIsCrypto;

  const QuoteWidget({
    Key key,
    @required this.allowPushRoute,
    @required this.index,
    @required this.isCrypto,
    @required this.ifIsCrypto,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (allowPushRoute) {
            if (focusNode != null) {
              focusNode?.unfocus();
            }
            if (!isCrypto) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (c) => QuoteInformation(quote: index)));
            } else {
              ifIsCrypto.showSnackBar(SnackBar(
                content: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.error),
                    Expanded(
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            child: Text(
                              "Crypto support limited!",
                              style: TextStyle(
                                fontFamily: "Montserrat",
                                //fontSize: 12.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ))),
                  ],
                ),
                action: SnackBarAction(
                    label: "OK",
                    onPressed: () {
                      ifIsCrypto.removeCurrentSnackBar();
                    }),
              ));
            }
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Container(
                    width: 32.0,
                    height: 32.0,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      //color: Colors.white70
                    ),
                    //radius: 16.0,
                    child: CustomCircleAvatar(
                      myImage: NetworkImage(
                        "https://storage.googleapis.com/iex/api/logos/${index.symbol.toUpperCase()}.png",
                      ),
                      initials: index.symbol.substring(0, 1),
                    )),
                const Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("${index.companyName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          )),
                      Text("${index.symbol}",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14.0,
                          ))
                    ],
                  ),
                ),
                /*Text("+16.32%", textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 28.0,
                      ))*/
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              // mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    "\$${numToSimple(index.delayedPrice ?? index.latestPrice)}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black87,
                        // fontFamily: 'Pacifico',
                        fontWeight: FontWeight.w400,
                        fontSize: 20.0),
                  ),
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 4.0)),
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            const Spacer(),
                            CircleAvatar(
                              radius: 12.0,
                              backgroundColor: (index.changePercent * 100) > 0
                                  ? Colors.green
                                  : Colors.red,
                              child: Icon(
                                index.change > 0
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                                color: Colors.white,
                                size: 12.0,
                              ),
                            ),
                            //const Spacer(,),
                            Text(
                              " ${(index.changePercent * 100) > 0 ? '+' : ''}${(index.changePercent * 100).toStringAsFixed(2)}%",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.black87,
                                  // fontFamily: 'Pacifico',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 20.0),
                            ),
                            Container(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  "(${numToSimple(index.change)})",
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                      color: Colors.black87,
                                      // fontFamily: 'Pacifico',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14.0),
                                )),
                          ],
                        ))),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Text(
                    "P/E: ${numToSimple(index.peRatio)}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black87,
                        // fontFamily: 'Pacifico',
                        //fontWeight: FontWeight.bold,
                        fontSize: 14.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    "HGH: \$${numToSimple(index.high)}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black87,
                        // fontFamily: 'Pacifico',
                        //fontWeight: FontWeight.bold,
                        fontSize: 14.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Text(
                    "LOW: \$${numToSimple(index.low)}",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black87,
                        // fontFamily: 'Pacifico',
                        //fontWeight: FontWeight.bold,
                        fontSize: 14.0),
                  ),
                ),
              ],
            ),
            Container(
                padding: const EdgeInsets.all(2.0),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "M/CAP: ${numToSimple(index.marketCap)}",
                      //textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Colors.black87,
                          // fontFamily: 'Pacifico',
                          //fontWeight: FontWeight.bold,
                          fontSize: 14.0),
                    ),
                    Text(
                      index.latestTime,
                      //textAlign: TextAlign.left,
                      style: TextStyle(
                          color: Colors.black87,
                          // fontFamily: 'Pacifico',
                          //fontWeight: FontWeight.bold,
                          fontSize: 14.0),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  String tmFromNow(DateTime day) {
    Duration diff = DateTime.now().difference(day);
    if (diff.inDays > 0) {
      return "${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago";
    } else if (diff.inHours > 0) {
      return "${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago";
    } else if (diff.inMinutes > 0) {
      return "${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago";
    } else if (diff.inSeconds > 0) {
      return "${diff.inSeconds} second${diff.inSeconds > 1 ? 's' : ''} ago";
    } else {
      return "less than a second ago";
    }
  }

  String numToSimple(dynamic num) {
    if (num == null) {
      return "N/A";
    }
    if (num > 1000000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} T";
    } else if (num > 1000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} B";
    } else if (num > 1000000) {
      return "${((num / 1000000) as double).toStringAsFixed(2)} M";
    } else if (num > 1000) {
      return "${((num / 1000) as double).toStringAsFixed(2)} K";
    } else {
      if (num is int) {
        return num.toDouble().toStringAsFixed(2);
      }
      return (num as double)?.toStringAsFixed(2);
    }
  }
}

class QuoteInformation extends StatefulWidget {
  final Quote quote;

  QuoteInformation({@required this.quote});

  @override
  _QuoteInformationState createState() => _QuoteInformationState();
}

class _QuoteInformationState extends State<QuoteInformation> {
  ChartsBloc chartsBloc;
  CompanyBloc companyBloc;
  StatsBloc statsBloc;
  PeersBloc peersBloc;
  FinancialsBloc financialsBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // final DateFormat formatter = new DateFormat('yyyy-MM-dd');
  ChartDurations _activechartDuration = ChartDurations.THREE_MONTHS;
  double _lowerValue = 0.0;
  bool isMissing = false;

  final Map<String, ChartDurations> chartDatesMaps = {
    '1D': ChartDurations.ONE_DAY,
    '1M': ChartDurations.ONE_MONTH,
    '3M': ChartDurations.THREE_MONTHS,
    '6M': ChartDurations.SIX_MONTHS,
    'YTD': ChartDurations.YEAR_TO_DATE,
    '1Y': ChartDurations.ONE_YEAR,
    '2Y': ChartDurations.TWO_YEAR,
    '5Y': ChartDurations.FIVE_YEAR
  };

  final List<String> chartDates = [
    '1D',
    '1M',
    '3M',
    '6M',
    'YTD',
    '1Y',
    '2Y',
    '5Y',
  ];

  @override
  void initState() {
    super.initState();
    IexApiProxy proxy = IexApiProxy.getInstance();
    chartsBloc = ChartsBloc(proxy, widget.quote.symbol);
    companyBloc = CompanyBloc(proxy, widget.quote.symbol);
    statsBloc = StatsBloc(proxy, widget.quote.symbol);
    peersBloc = PeersBloc(proxy, widget.quote.symbol);
    financialsBloc = FinancialsBloc(proxy, widget.quote.symbol);
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      await launch(
        url,
        option: CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: CustomTabsAnimation.slideIn(),
          // or user defined animation.
          /*animation: new CustomTabsAnimation(
          startEnter: 'slide_up',
          startExit: 'android:anim/fade_out',
          endEnter: 'android:anim/fade_in',
          endExit: 'slide_down',
        ),*/
          extraCustomTabs: <String>[
            // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
            'org.mozilla.firefox',
            // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
            'com.microsoft.emmx',
          ],
        ),
      );
    } catch (e) {
      // An exception is thrown if browser app is not installed on Android device.
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).backgroundColor,
      child: SafeArea(
        child: Scaffold(
            backgroundColor: Theme.of(context).backgroundColor,
            key: _scaffoldKey,
            body: NestedScrollView(
                headerSliverBuilder: (_, __) {
                  return [
                    //  _titleSliverBoxSection("Charts", "Historical data for charts"),
                    SliverAppBar(
                      flexibleSpace: ListTile(
                        trailing: IconButton(
                          icon: Icon(
                            Icons.home,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context)
                                .popUntil((p) => !p.navigator.canPop());
                          },
                        ),
                      ),
                    ),
                  ];
                },
                body: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    _titleSliverBoxSection("Profile",
                        "Historical data for ${widget.quote.symbol}"),
                    SliverToBoxAdapter(
                        child: Container(
                      height: 200,
                      child: StreamBuilder(
                        builder: (con, snapshot) {
                          return AnimatedCrossFade(
                              firstCurve: Curves.fastOutSlowIn,
                              secondCurve: Curves.fastOutSlowIn,
                              firstChild: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.0),
                                      child: (snapshot.connectionState ==
                                              ConnectionState.none)
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.refresh,
                                                color: Colors.white70,
                                                size: 32.0,
                                              ),
                                              onPressed: () {
                                                chartsBloc
                                                    .fetchDifferentDuration(
                                                        ChartDurations
                                                            .THREE_MONTHS);
                                              },
                                            )
                                          : const Center(
                                              child:
                                                  const CircularProgressIndicator()),
                                    )
                                  ]),
                              secondChild: (snapshot.hasData
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Container(
                                          height: 160,
                                          margin: EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Color.fromRGBO(
                                                      0, 0, 0, 0.35),
                                                  blurRadius: 8.0),
                                            ],
                                          ),
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16.0, horizontal: 8.0),
                                          child: OHLCVGraph(
                                              data:
                                                  (snapshot.data as ChartModel)
                                                      .chartToOHLC(),
                                              enableGridLines: true,
                                              volumeProp: 0.2),
                                        ),
                                        Container(
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            padding:
                                                EdgeInsets.only(right: 20.0),
                                            height: 20.0,
                                            decoration: BoxDecoration(
                                                color: Colors.white70,
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(4.0))),
                                            child: Slider(
                                              value: _lowerValue,
                                              onChanged: (d) {
                                                setState(() {
                                                  _lowerValue = d;
                                                });
                                              },
                                              label:
                                                  "${(snapshot.data as ChartModel).chartData[(_lowerValue.toInt())].label}: \$${numToSimple((snapshot.data as ChartModel).chartData[(_lowerValue.toInt())].close) ?? 'N/A'}",
                                              max: (snapshot.data as ChartModel)
                                                          .chartData
                                                          .length >
                                                      0
                                                  ? ((snapshot.data
                                                                  as ChartModel)
                                                              .chartData
                                                              .length -
                                                          1)
                                                      .toDouble()
                                                  : 0,
                                              min: 0,
                                              divisions:
                                                  ((snapshot.data as ChartModel)
                                                      .chartData
                                                      .length),
                                              activeColor:
                                                  Theme.of(context).accentColor,
                                            ))
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.refresh,
                                              color: Colors.white70,
                                              size: 32.0,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                chartsBloc
                                                    .fetchDifferentDuration(
                                                        ChartDurations
                                                            .THREE_MONTHS);
                                              });
                                            },
                                          ),
                                          Container(
                                            padding: EdgeInsets.all(8.0),
                                            child: (snapshot.hasError)
                                                ? Text(
                                                    "Data retrieval error, Tap to retry",
                                                    textAlign: TextAlign.center,
                                                  )
                                                : const Center(
                                                    child: Text(
                                                        "Connection problems")),
                                          )
                                        ])),
                              crossFadeState: (snapshot.connectionState !=
                                      ConnectionState.done)
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: Duration(milliseconds: 800));
                        },
                        stream: chartsBloc.chartsStream,
                      ),
                    )),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 50.0,
                        alignment: Alignment.center,
                        margin: EdgeInsets.all(8.0),
                        child: Wrap(
                          //alignment: WrapAlignment.center,
                          //mainAxisSize: MainAxisSize.max,
                          // mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                              chartDates.length,
                              (index) => Container(
                                  constraints: BoxConstraints(maxWidth: 64.0),
                                  margin: EdgeInsets.symmetric(horizontal: 2.0),
                                  child: FlatButton(
                                      color:
                                          chartDatesMaps[chartDates[index]] ==
                                                  _activechartDuration
                                              ? Theme.of(context).accentColor
                                              : Colors.white,
                                      onPressed: () {
                                        setState(() {
                                          if (chartDatesMaps[
                                                  chartDates[index]] ==
                                              ChartDurations.ONE_YEAR) {
                                            chartsBloc
                                                .fetchDifferentDurationIntervals(
                                                    chartDatesMaps[
                                                        chartDates[index]],
                                                    7);
                                          } else if (chartDatesMaps[
                                                  chartDates[index]] ==
                                              ChartDurations.FIVE_YEAR) {
                                            chartsBloc
                                                .fetchDifferentDurationIntervals(
                                                    chartDatesMaps[
                                                        chartDates[index]],
                                                    7);
                                          } else {
                                            chartsBloc.fetchDifferentDuration(
                                                chartDatesMaps[
                                                    chartDates[index]]);
                                          }
                                          _activechartDuration =
                                              chartDatesMaps[chartDates[index]];
                                          _lowerValue = 0;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(2.0),
                                        child: Text(
                                          chartDates[index],
                                          style: TextStyle(fontSize: 12.0),
                                        ),
                                      )))),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                        child: Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.all(8.0),
                      child: GradientColorCard(
                        child: QuoteWidget(
                          index: widget.quote,
                          allowPushRoute: false,
                          isCrypto: widget.quote.sector == "cryptocurrency",
                          ifIsCrypto: _scaffoldKey.currentState,
                        ),
                        kColora: widget.quote.kColora,
                        kColorb: widget.quote.kColorb,
                      ),
                    )),
                    SliverToBoxAdapter(
                      child: Container(
                        //height: 250.0,
                        margin: EdgeInsets.all(8.0),
                        child: Column(
                          children: <Widget>[
                            StreamBuilder(
                                stream: companyBloc.infoStream,
                                builder: (_, snapshot) {
                                  return AnimatedCrossFade(
                                      firstCurve: Curves.fastOutSlowIn,
                                      secondCurve: Curves.fastOutSlowIn,
                                      firstChild: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(8.0),
                                              child: (snapshot
                                                          .connectionState ==
                                                      ConnectionState.none)
                                                  ? IconButton(
                                                      icon: Icon(Icons.refresh,
                                                          size: 32.0,
                                                          color:
                                                              Colors.white70),
                                                      onPressed: () {
                                                        setState(() {
                                                          companyBloc.refresh();
                                                        });
                                                      },
                                                    )
                                                  : const Center(
                                                      child:
                                                          const CircularProgressIndicator()),
                                            )
                                          ]),
                                      secondChild: (snapshot.hasData
                                          ? Wrap(
                                              spacing: 8.0,
                                              runSpacing: 8.0,
                                              alignment: WrapAlignment.center,
                                              children: <Widget>[
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  width: 200.0,
                                                  child: _titledColumn(
                                                    "Description",
                                                    (snapshot.data
                                                                as CompanyModel)
                                                            .description
                                                            .isEmpty
                                                        ? "No Description available"
                                                        : (snapshot.data
                                                                as CompanyModel)
                                                            .description,
                                                  ),
                                                ),
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  width: 110.0,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Text(
                                                        "Avg Volume",
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                        numToSimple(widget.quote
                                                            .avgTotalVolume),
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      4.0)),
                                                      Text(
                                                        "Open",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                        "\$${numToSimple(widget.quote.open)}",
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      4.0)),
                                                      Text(
                                                        "Close",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                        "\$${numToSimple(widget.quote.close)}",
                                                        maxLines: 9,
                                                        //textAlign: TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  width: 80.0,
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: <Widget>[
                                                      Text(
                                                        "Open time",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                       // "${widget.quote.openTime.day}/${widget.quote.openTime.month}/${widget.quote.openTime.year}",
                                                        "Unstable!",
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      4.0)),
                                                      Text(
                                                        "Prev. close",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                        //"${widget.quote.closeTime.day}/${widget.quote.closeTime.month}/${widget.quote.closeTime.year}",
                                                        "Unstable",
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  width: 200.0,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Text(
                                                        "CEO",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      InkWell(
                                                          child: RichText(
                                                        text: TextSpan(
                                                            text: (snapshot.data
                                                                    as CompanyModel)
                                                                .ceo,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 12.0,
                                                                fontFamily:
                                                                    "Montserrat",
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline),
                                                            recognizer:
                                                                TapGestureRecognizer()
                                                                  ..onTap = () {
                                                                    String uri =
                                                                        "https://www.google.com/search?q=${(snapshot.data as CompanyModel).ceo.split(' ').join('+')}";

                                                                    _launchURL(
                                                                        context,
                                                                        uri);
                                                                  }),
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      )),
                                                      Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      4.0)),
                                                      Text(
                                                        "Website",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      RichText(
                                                        text: TextSpan(
                                                            text: (snapshot.data
                                                                    as CompanyModel)
                                                                .website,
                                                            recognizer:
                                                                TapGestureRecognizer()
                                                                  ..onTap = () {
                                                                    _launchURL(
                                                                        context,
                                                                        (snapshot.data
                                                                                as CompanyModel)
                                                                            .website);
                                                                  },
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontFamily:
                                                                    "Montserrat",
                                                                fontSize: 12.0,
                                                                decoration:
                                                                    TextDecoration
                                                                        .underline)),
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        /* (snapshot.data
                                                                as CompanyModel)
                                                            .website,
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),*/
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  width: 110.0,
                                                  child: Column(
                                                    children: <Widget>[
                                                      Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  vertical:
                                                                      4.0)),
                                                      Text(
                                                        "Sector",
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Divider(
                                                        color: Colors.white,
                                                      ),
                                                      Text(
                                                        snapshot.data.sector,
                                                        maxLines: 9,
                                                        textAlign:
                                                            TextAlign.justify,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                  IconButton(
                                                    icon: Icon(Icons.refresh,
                                                        size: 32.0,
                                                        color: Colors.white70),
                                                    onPressed: () {
                                                      setState(() {
                                                        companyBloc.refresh();
                                                      });
                                                    },
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: (snapshot.hasError)
                                                        ? Text(
                                                            "Data retrieval error",
                                                            textAlign: TextAlign
                                                                .center,
                                                          )
                                                        : const Center(
                                                            child: Text(
                                                                "Connection problems")),
                                                  )
                                                ])),
                                      crossFadeState:
                                          (snapshot.connectionState !=
                                                  ConnectionState.done)
                                              ? CrossFadeState.showFirst
                                              : CrossFadeState.showSecond,
                                      duration: Duration(milliseconds: 800));
                                })
                          ],
                        ),
                      ),
                    ),
                    _titleSliverBoxSection("Key Stats",
                        "Key information about ${widget.quote.symbol}"),
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.all(8.0),
                        alignment: Alignment.center,
                        child: StreamBuilder(
                          stream: statsBloc.keyStream,
                          builder: (context, snapshot) {
                            return AnimatedCrossFade(
                                firstCurve: Curves.fastOutSlowIn,
                                secondCurve: Curves.fastOutSlowIn,
                                sizeCurve: Curves.easeIn,
                                // alignment: Alignment.bottomCenter,
                                firstChild: (snapshot.connectionState ==
                                        ConnectionState.none)
                                    ? const Center(
                                        child: const Icon(
                                        Icons.cloud_off,
                                        color: Colors.white,
                                        size: 32.0,
                                      ))
                                    : const Center(
                                        child:
                                            const CircularProgressIndicator()),
                                secondChild: (!snapshot.hasData
                                    ? Center(
                                        child: IconButton(
                                        icon: Icon(Icons.refresh,
                                            size: 32.0, color: Colors.white70),
                                        onPressed: () {
                                          setState(() {
                                            statsBloc.refresh();
                                          });
                                        },
                                      ))
                                    : //KeyStats stats = (snapshot.data as KeyStats);
                                    //return
                                    Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        runAlignment: WrapAlignment.center,
                                        // alignment: WrapAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            width: 100,
                                            alignment: Alignment.center,
                                            //padding: EdgeInsets.symmetric(horizontal: 16.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  "Wk52 HIGH",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  numToSimple(
                                                      snapshot.data.week52High),
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Wk52 LOW",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "\$${numToSimple(snapshot.data.week52low)}",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Wk52 CHANGE",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  numToSimple(snapshot
                                                      .data.week52change),
                                                  maxLines: 9,
                                                  //textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 100,
                                            alignment: Alignment.center,
                                            // padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  "Float",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "\$${numToSimple(snapshot.data.float)}",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Beta",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.beta)}",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Cash",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  numToSimple(
                                                      snapshot.data.cash),
                                                  maxLines: 9,
                                                  //textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 100,
                                            alignment: Alignment.center,
                                            //padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  "P/E HIGH",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  numToSimple(snapshot
                                                      .data.peRatioHigh),
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "P/E LOW",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.peRatioLow)}",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Revenue(TTM)",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  numToSimple(
                                                      snapshot.data.revenueTTM),
                                                  maxLines: 9,
                                                  //textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 100,
                                            alignment: Alignment.center,
                                            //padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  "R.O.Assets",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.returnOnAssetsTTM)}%",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "R.O.Equity",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.returnOnEquityTTM)}%",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "R.0.Capital",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.returnOnCapitalTTM)}%",
                                                  maxLines: 9,
                                                  //textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            width: 100,
                                            alignment: Alignment.center,

                                            //padding: EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Column(
                                              children: <Widget>[
                                                Text(
                                                  "Profit Margin",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.profitMargin)}%",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Price to Sales",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.priceToSales)}",
                                                  maxLines: 9,
                                                  textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 4.0)),
                                                Text(
                                                  "Price to Margin",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                Divider(
                                                  color: Colors.white,
                                                ),
                                                Text(
                                                  "${numToSimple(snapshot.data.priceToMargin)}",
                                                  maxLines: 9,
                                                  //textAlign: TextAlign.justify,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )),
                                crossFadeState: (snapshot.connectionState !=
                                        ConnectionState.done)
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                duration: Duration(milliseconds: 900));
                          },
                        ),
                      ),
                    ),
                    SliverPadding(padding: EdgeInsets.symmetric(vertical: 8.0)),
                    /*_titleSliverBoxSection(
                        "Financials", "Similar securities to this"),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Colors.transparent,
                        ),
                        height: isMissing ? 200 : 850,
                          child: StreamBuilder(
                              stream: financialsBloc.financialsStream,
                              builder: (context, snapshot) {
                                return AnimatedCrossFade(
                                    firstCurve: Curves.fastOutSlowIn,
                                    secondCurve: Curves.fastOutSlowIn,
                                    sizeCurve: Curves.easeIn,
                                    // alignment: Alignment.bottomCenter,
                                    firstChild: (snapshot.connectionState ==
                                        ConnectionState.none)
                                        ?  Center(
                                        child: IconButton(
                                          icon: Icon(Icons.refresh,
                                              size: 32.0, color: Colors.white70),
                                          onPressed: (){
                                            setState(() {
                                              financialsBloc.refresh();
                                            });
                                          },
                                        ))
                                        : const Center(
                                        child:
                                        const CircularProgressIndicator()),
                                    secondChild: (!snapshot.hasData
                                        ? Center(
                                        child: const Icon(
                                          Icons.cloud_off,
                                          color: Colors.white,
                                          size: 32.0,
                                        ))
                                        : (snapshot.data.length > 0
                                        ? ListView.builder(
                                      itemCount: 1,
                                      itemBuilder:
                                          (BuildContext c, int i) {
                                        return Container(
                                          margin: EdgeInsets.symmetric(horizontal: 16.0),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8.0),
                                          ),
                                          child: createDataTables(snapshot),
                                        );
                                      },
                                      physics:
                                      const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(
                                          left: 40.0),
                                      scrollDirection:
                                      Axis.horizontal,
                                    )
                                        : Center(
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        mainAxisSize:
                                        MainAxisSize.max,
                                        children: <Widget>[
                                          Icon(
                                            Icons.hourglass_empty,
                                            size: 32.0,
                                            color: Colors.white,
                                          ),
                                          Container(
                                            margin:
                                            EdgeInsets.all(4.0),
                                            child: Text(
                                              "Peer information not added!",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontStyle:
                                                FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ))),
                                    crossFadeState: (snapshot.connectionState !=
                                        ConnectionState.done)
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    duration: Duration(milliseconds: 900));
                              })
                      ),
                    ),
                    SliverPadding(padding: EdgeInsets.symmetric(vertical: 8.0)),*/
                    _titleSliverBoxSection(
                        "Peers", "Similar securities to this"),
                    SliverToBoxAdapter(
                      child: Container(
                          //color: Colors.blue,
                          padding: EdgeInsets.only(bottom: 16.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.transparent,
                          ),
                          height: kOverlayBoxHeight + 4.0,
                          //margin: EdgeInsets.only(bottom: 50.0),
                          child: StreamBuilder(
                              stream: peersBloc.peerStream,
                              builder: (context, snapshot) {
                                return AnimatedCrossFade(
                                    firstCurve: Curves.fastOutSlowIn,
                                    secondCurve: Curves.fastOutSlowIn,
                                    sizeCurve: Curves.easeIn,
                                    // alignment: Alignment.bottomCenter,
                                    firstChild: (snapshot.connectionState ==
                                            ConnectionState.none)
                                        ? Center(
                                            child: IconButton(
                                            icon: Icon(Icons.refresh,
                                                size: 32.0,
                                                color: Colors.white70),
                                            onPressed: () {
                                              setState(() {
                                                peersBloc.refresh();
                                              });
                                            },
                                          ))
                                        : const Center(
                                            child:
                                                const CircularProgressIndicator()),
                                    secondChild: (!snapshot.hasData
                                        ? Center(
                                            child: IconButton(
                                              icon: Icon(Icons.refresh,
                                                  size: 32.0,
                                                  color: Colors.white70),
                                              onPressed: () {
                                                setState(() {
                                                  peersBloc.refresh();
                                                });
                                              },
                                            ))
                                        : (snapshot.data.length > 0
                                            ? ListView.builder(
                                                itemCount: snapshot.data.length,
                                                itemBuilder:
                                                    (BuildContext c, int i) {
                                                  Quote index = (snapshot
                                                      .data[i] as Quote);
                                                  return GradientColorCard(
                                                      kColora: snapshot
                                                          .data[i].kColora,
                                                      kColorb: snapshot
                                                          .data[i].kColorb,
                                                      child: QuoteWidget(
                                                        index: index,
                                                        allowPushRoute: true,
                                                        isCrypto: index
                                                                .sector ==
                                                            "cryptocurrency",
                                                        ifIsCrypto: _scaffoldKey
                                                            .currentState,
                                                      ));
                                                },
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                padding: const EdgeInsets.only(
                                                    left: 40.0),
                                                scrollDirection:
                                                    Axis.horizontal,
                                              )
                                            : Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: <Widget>[
                                                    Icon(
                                                      Icons.hourglass_empty,
                                                      size: 32.0,
                                                      color: Colors.white,
                                                    ),
                                                    Container(
                                                      margin:
                                                          EdgeInsets.all(4.0),
                                                      child: Text(
                                                        "Peer information not added!",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ))),
                                    crossFadeState: (snapshot.connectionState !=
                                            ConnectionState.done)
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    duration: Duration(milliseconds: 900));
                              })),
                      //);
                    ),
                  ],
                ))),
      ),
    );
  }

  Widget createDataTables(AsyncSnapshot snapshot) {
    List<FinancialsModel> _finList = (snapshot.data as List<FinancialsModel>);
    if (_finList.length != 4) {
      setState(() {
        isMissing = true;
      });
      return Center(
          child: Text(
        "Insufficient Data!",
        style: TextStyle(color: Colors.white),
      ));
    }
    if (isMissing) {
      setState(() {
        isMissing = false;
      });
    }
    return DataTable(columns: <DataColumn>[
      DataColumn(
        label: Text("Value"),
        numeric: false,
      ),
      DataColumn(
        label: Text(
            "${_finList.first.reportDate.year}-${_finList.first.reportDate.month}-${_finList.first.reportDate.day}"),
        numeric: false,
      ),
      DataColumn(
        label: Text(
            "${_finList[1].reportDate.year}-${_finList[1].reportDate.month}-${_finList[1].reportDate.day}"),
        numeric: false,
      ),
      DataColumn(
        label: Text(
            "${_finList[2].reportDate.year}-${_finList[2].reportDate.month}-${_finList[2].reportDate.day}"),
        numeric: false,
      ),
      DataColumn(
        label: Text(
            "${_finList[3].reportDate.year}-${_finList[3].reportDate.month}-${_finList[3].reportDate.day}"),
        numeric: false,
      ),
    ], rows: <DataRow>[
      DataRow(
        cells: cellRepresentation(
            "Research and Dev", (i) => _finList[i].researchAndDevelopment),
      ),
      DataRow(
        cells: cellRepresentation(
            "Operating Expense", (i) => _finList[i].operatingExpense),
      ),
      DataRow(
        cells: cellRepresentation(
            "Operating Income", (i) => _finList[i].operatingIncome),
      ),
      DataRow(
        cells: cellRepresentation("Net Income", (i) => _finList[i].netIncome),
      ),
      DataRow(
        cells: cellRepresentation(
            "Total Revenue", (i) => _finList[i].totalRevenue),
      ),
      DataRow(
        cells: cellRepresentation(
            "Cost of Revenue", (i) => _finList[i].costOfRevenue),
      ),
      DataRow(
        cells:
            cellRepresentation("Gross Profit", (i) => _finList[i].grossProfit),
      ),
      DataRow(
        cells: cellRepresentation(
            "Current Assets", (i) => _finList[i].currentAssets),
      ),
      DataRow(
        cells:
            cellRepresentation("Current Debt", (i) => _finList[i].currentDebt),
      ),
      DataRow(
        cells: cellRepresentation("Total Debt", (i) => _finList[i].totalDebt),
      ),
      DataRow(
        cells: cellRepresentation(
            "Total Liabilities", (i) => _finList[i].totalLiabilities),
      ),
      DataRow(
        cells:
            cellRepresentation("Current Cash", (i) => _finList[i].currentCash),
      ),
      DataRow(
        cells: cellRepresentation("Total Cash", (i) => _finList[i].totalCash),
      ),
      DataRow(
        cells: cellRepresentation(
            "Shareholder Equity", (i) => _finList[i].shareHolderEquity),
      ),
      DataRow(
        cells: cellRepresentation("Cash Change", (i) => _finList[i].cashChange),
      ),
      DataRow(
        cells: cellRepresentation("Cash flow", (i) => _finList[i].cashFlow),
      ),
    ]);
  }

  List<DataCell> cellRepresentation(String title, Function applicator) {
    return [
      DataCell(Text(
        title,
        style: TextStyle(fontFamily: "Montserrat", fontWeight: FontWeight.bold),
      )),
      DataCell(Text(numToSimple(applicator(0)))),
      DataCell(Text(numToSimple(applicator(1)))),
      DataCell(Text(numToSimple(applicator(2)))),
      DataCell(Text(numToSimple(applicator(3)))),
    ];
  }

  String numToSimple(dynamic num) {
    if (num == null) {
      return "N/A";
    }
    if (num.abs() > 1000000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} T";
    } else if (num.abs() > 1000000000) {
      return "${((num / 1000000000) as double).toStringAsFixed(2)} B";
    } else if (num.abs() > 1000000) {
      return "${((num / 1000000) as double).toStringAsFixed(2)} M";
    } else if (num.abs() > 1000) {
      return "${((num / 1000) as double).toStringAsFixed(2)} K";
    } else {
      if (num is int) {
        return num.toDouble().toStringAsFixed(2);
      }
      return (num as double)?.toStringAsFixed(2);
    }
  }

  Widget _titleSliverBoxSection(
    String title,
    String description,
  ) {
    return SliverPadding(
        padding: EdgeInsets.symmetric(vertical: 4.0),
        sliver: SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            height: 84.0,
            alignment: Alignment.centerLeft,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28.0),
                ),
                const Divider(
                  color: Colors.white70,
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.white, fontSize: 14.0),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _titledColumn(String title, String info) {
    return Column(
      children: <Widget>[
        Text(
          title,
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Divider(
          color: Colors.white,
        ),
        Text(
          info,
          maxLines: 9,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

class AttributionPage extends StatefulWidget {
  @override
  _AttributionPageState createState() => new _AttributionPageState();
}

class _AttributionPageState extends State<AttributionPage> {
  bool isAgreed = false;
  bool isSaving = true;

  Future<bool> getAgreedState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAgreedPref') ?? false;
  }

  Future<bool> saveAgreedState(bool state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAgreedPref', state);
    print('saving ${state.toString()}');
    return state;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: isAgreed
            ? () {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => ValuePeekHome()));
              }
            : null,
        child: Icon(
          Icons.navigate_next,
          color: isAgreed ? Colors.black87 : Colors.grey,
        ),
      ),
      body: Center(
        child: Container(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(4.0),
                child: Text(
                  "YAME",
                  style: TextStyle(
                    fontSize: 24.0,
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(4.0),
                child: Text(
                  "Yet Another Market Explorer",
                  style: TextStyle(
                    fontFamily: 'Pacifico',
                    fontStyle: FontStyle.italic,
                    fontSize: 12.0,
                    color: Colors.white,
                  ),
                ),
              ),
              AttributionWidget(),
              Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FutureBuilder<bool>(
                        future: getAgreedState(),
                        builder: (context, snapshot) {
                          return Checkbox(
                            value: snapshot.data ?? false,
                            onChanged: (bool newVal) {
                                saveAgreedState(newVal).then((d) {
                                  setState(() {
                                    isAgreed = d;
                                  });
                              }).catchError((e)=>print(e));
                            },
                          );
                        }),
                    Container(
                      padding: EdgeInsets.all(4.0),
                      child: Text(
                        "I agree to the terms of use",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ])
            ],
          ),
        ),
      ),
    );
  }
}

class AttributionWidget extends StatelessWidget {
  void _launchURL(BuildContext context, String site) async {
    try {
      await launch(
        site,
        option: new CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: new CustomTabsAnimation.slideIn(),
          // or user defined animation.
          extraCustomTabs: <String>[
            // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
            'org.mozilla.firefox',
            // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
            'com.microsoft.emmx',
          ],
        ),
      );
    } catch (e) {
      // An exception is thrown if browser app is not installed on Android device.
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return new RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
          text: "Data provided for free by ",
          style: TextStyle(fontFamily: 'Montserrat'),
          children: [
            TextSpan(
                text: "IEX.",
                style: TextStyle(decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () =>
                      _launchURL(context, "https://iextrading.com/developer")),
            TextSpan(text: " View", children: []),
            TextSpan(
                text: " IEX’s Terms of Use",
                style: TextStyle(decoration: TextDecoration.underline),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _launchURL(
                      context, "https://iextrading.com/api-exhibit-a/"))
          ]),
    );
  }
}
