import 'package:peek/blocs/sectors_bloc.dart';
import 'package:peek/blocs/charts_bloc.dart';
import 'package:peek/blocs/lists_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:peek/network/iex_api_proxy.dart';

class IexApiProvider extends InheritedWidget {
  final SectorBloc sectorBloc;
  final ListsBloc listsBloc;
  final LosersListBloc losersListBloc;
  final InfocusListBloc infocusListBloc;

  static SectorBloc sectorBlocOf(BuildContext context) {
    var x = (context.inheritFromWidgetOfExactType(IexApiProvider)
        as IexApiProvider);
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
    return (context.inheritFromWidgetOfExactType(IexApiProvider)
            as IexApiProvider)
        .listsBloc;
  }

  static LosersListBloc losersListBlocOf(BuildContext context){
    return (context.inheritFromWidgetOfExactType(IexApiProvider)
    as IexApiProvider).losersListBloc;
  }

  static InfocusListBloc infocusListBlocOf(BuildContext context){
    return (context.inheritFromWidgetOfExactType(IexApiProvider)
    as IexApiProvider).infocusListBloc;
  }

  @override
  bool updateShouldNotify(_) {
    print("Notify!!");
    // TODO: implement updateShouldNotify
    return true;
  }
}
