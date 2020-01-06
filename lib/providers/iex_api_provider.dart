import 'package:yame/blocs/sectors_bloc.dart';
import 'package:yame/blocs/lists_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:yame/network/iex_api_proxy.dart';

class IexApiProvider extends InheritedWidget {

  final SectorBloc sectorBloc;
  final ListsBloc listsBloc;
  final LosersListBloc losersListBloc;
  final InfocusListBloc infocusListBloc;

  static SectorBloc sectorBlocOf(BuildContext context) {
    var x = (context.dependOnInheritedWidgetOfExactType<IexApiProvider>());
    return x.sectorBloc;
  }

  IexApiProvider(
      {Key key,
      Widget child,
      SectorBloc sBloc,
      LosersListBloc loBloc,
      InfocusListBloc infoBloc,
      ListsBloc lBloc})
      : this.sectorBloc =
            sBloc != null ? sBloc : SectorBloc(IexApiProxy.getInstance()),
        this.infocusListBloc = infoBloc != null
            ? infoBloc
            : InfocusListBloc(IexApiProxy.getInstance()),
        this.losersListBloc =
            loBloc != null ? loBloc : LosersListBloc(IexApiProxy.getInstance()),
        this.listsBloc =
            lBloc != null ? lBloc : ListsBloc(IexApiProxy.getInstance()),
        super(child: child, key: key);

  static ListsBloc listsBlocOf(BuildContext context) {
    return (context.dependOnInheritedWidgetOfExactType<IexApiProvider>())
        .listsBloc;
  }

  static LosersListBloc losersListBlocOf(BuildContext context) {
    return (context.dependOnInheritedWidgetOfExactType<IexApiProvider>())
        .losersListBloc;
  }

  static InfocusListBloc infocusListBlocOf(BuildContext context) {
    return (context.dependOnInheritedWidgetOfExactType<IexApiProvider>())
        .infocusListBloc;
  }

  @override
  bool updateShouldNotify(_) {
    print("Notify!!");
    return true;
  }
}
