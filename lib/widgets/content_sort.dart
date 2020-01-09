import 'package:auto_size_text/auto_size_text.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/widgets/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ContentSort extends StatefulWidget {
  final List<String> types;

  const ContentSort({@required this.types, Key key}) : super(key: key);

  @override
  _ContentSortState createState() => _ContentSortState();
}

class _ContentSortState extends State<ContentSort> with TickerProviderStateMixin {

  String _typeFilter = "";

  AnimationController _timeExpansionController;
  AnimationController _typeExpansionController;

  @override
  void initState() { 
    super.initState();
    _timeExpansionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _typeExpansionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1.0);
  }

  @override
  void dispose() { 
    _timeExpansionController.dispose();
    _typeExpansionController.dispose();
    super.dispose();
  }

  void _expand() {
    _timeExpansionController.animateTo(1.0, curve: Curves.ease);
    _typeExpansionController.animateTo(0.0, curve: Curves.ease);
  }

  void _reverse() {
    _typeFilter = "";
    _timeExpansionController.animateTo(0.0, curve: Curves.ease);
    _typeExpansionController.animateTo(1.0, curve: Curves.ease);
  }

  Future<bool> _willPop() {
    if (_timeExpansionController.value > 0.5) {
      _reverse();
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPop,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizeTransition(
            sizeFactor: _typeExpansionController,
            child: Column(
              children: <Widget>[
            const ActionSheetTitle(title: "Sort"),
              ]..addAll(_sortTypeParams(widget.types)),
            ),
          ),
          //const Divider(),
        ]..add(
          SizeTransition(
            sizeFactor: _timeExpansionController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionSheetTitle(
                  title: _typeFilter.isNotEmpty ? StringUtils.capitalize(_typeFilter) : "",
                  actionCallBack: _reverse,
                )
              ]..addAll(_sortTimeParams()),
            ),
          )
        ),
      )
    );
  }
  List<Widget> _sortTypeParams(List<String> types) {
    return List<Widget>.generate(types.length, (int index) {
      return ActionSheetInkwell(
        title: Row(children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 5.0),
            child: _getTypeIcon(types[index])
          ),
          Text(StringUtils.capitalize(types[index]))
        ]),
        onTap: () {
          var q = types[index];
          if (q == "hot" || q == "new" || q == "rising") {
            final sortType = parseTypeFilter(q);
            BlocProvider.of<PostsBloc>(context).add(ParamsChanged(typeFilter: sortType, timeFilter: ""));
            Navigator.of(context).pop();
          } else {
            setState(() {
              _typeFilter = types[index];
            });
            _expand();
          }
        },
      );
    });
  }
  List<Widget> _sortTimeParams() {
    return new List<Widget>.generate(sortTimes.length, (int index) {
      return ActionSheetInkwell(
        title: Row(children: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 5.0),
            child: _getTypeIcon(sortTimes[index])
          ),
          Text(StringUtils.capitalize(sortTimes[index]))
        ]),
        onTap: () {
          if (_typeFilter != "") {
            final sortType = parseTypeFilter(_typeFilter);
            final sortTime = sortTimes[index];
            BlocProvider.of<PostsBloc>(context).add(ParamsChanged(typeFilter: sortType, timeFilter: sortTime));
            Navigator.of(context).pop();
          }
        },
      );
    });
  }
}

Widget _getTypeIcon(String type) {
    switch (type) {
      // * Type sort icons:
      case 'new':
        return Icon(MdiIcons.newBox);
      case 'rising':
        return Icon(MdiIcons.trendingUp);
      case 'top':
        return Icon(MdiIcons.trophy);
      case 'controversial':
        return Icon(MdiIcons.swordCross);
      // * Age sort icons:
      case 'hour':
        return Icon(MdiIcons.clock);
      case '24h':
        return Text('24', style: LyreTextStyles.iconText);
      case 'week':
        return Icon(MdiIcons.calendarWeek);
      case 'month':
        return Icon(MdiIcons.calendarMonth);
      case 'year':
        return Text('365', style: LyreTextStyles.iconText.apply(fontSizeFactor: 2/3));
      case 'all time':
        return Icon(MdiIcons.infinity);
      default:
        //Defaults to hot
        return Icon(MdiIcons.fire);
    }
  }