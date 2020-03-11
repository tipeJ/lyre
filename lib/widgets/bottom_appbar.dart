import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/widgets/bottom_appbar_expanding.dart' as prefix0;

///Class for wrapping a scaffold body for a custom bottom expanding appBar
class PersistentBottomAppbarWrapper extends StatelessWidget {
  /// The body content
  final Widget body;
  /// The content shown in the appbar itself
  final Widget appBarContent;
  /// The content for the expanding part of the bottom sheet
  final State<ExpandingSheetContent> expandingSheetContent;
  /// The full expanded height of the expanded bottom sheet
  final double fullSizeHeight;

  final height = 56.0;

  const PersistentBottomAppbarWrapper({Key key, @required this.body, this.appBarContent, this.expandingSheetContent, this.fullSizeHeight}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return expandingSheetContent != null
      ? _ExpandingBottomAppWrapper(
        body: body,
        appBarContent: appBarContent,
        expandingSheetContent: expandingSheetContent,
      )
      : _ExpandingBottomAppWrapper(
          body: body,
          appBarContent: appBarContent,
          expandingSheetContent: SubredditsList(),
        );
  }
}

class _ExpandingBottomAppWrapper extends StatelessWidget{

  final Widget body;
  final Widget appBarContent;
  final State<ExpandingSheetContent> expandingSheetContent;

  const _ExpandingBottomAppWrapper({
    @required this.body,
    @required this.expandingSheetContent,
    @required this.appBarContent,
  }) : 
    assert(body != null),
    assert(appBarContent != null),
    assert(expandingSheetContent != null);

  @override
  Widget build(BuildContext context) {
    final maxHeight = min(MediaQuery.of(context).size.height, MediaQuery.of(context).size.width);
    return Container(
      child: Stack(
        children: <Widget>[
          body,
          Align(
              alignment: Alignment.bottomCenter,
              //Expandable appbar
              child: prefix0.LyreDraggableScrollableSheet(
                expand: true,
                maxChildSize: maxHeight,
                minChildSize: kBottomNavigationBarHeight,
                borderRadius: BlocProvider.of<LyreBloc>(context).state.currentTheme.borderRadius.toDouble(),
                initialChildSize: kBottomNavigationBarHeight,
                builder: (context, scontrol) {
                  return ExpandingSheetContent(state: expandingSheetContent, innerController: scontrol, appBarContent: appBarContent, maxHeight: maxHeight);
                },
            )
          )
        ],
      )
    );
  }
}
class ExpandingSheetContent extends StatefulWidget {
  final State<ExpandingSheetContent> state;
  final double maxHeight;
  final Widget appBarContent;
  final prefix0.LyreDraggableScrollableSheetScrollController innerController;
  final ValueNotifier<bool> visible = ValueNotifier(true);

  ExpandingSheetContent({@required this.state, @required this.innerController, @required this.appBarContent, @required this.maxHeight});
  @override
  State<ExpandingSheetContent> createState() => state;
}
class _PersistentBottomAppWrapperWithoutExpansion extends StatelessWidget {
  final Widget body;
  final Widget appBarContent;

  const _PersistentBottomAppWrapperWithoutExpansion({
    @required this.body,
    @required this.appBarContent,
  }) : 
    assert(body != null),
    assert(appBarContent != null);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BlocProvider.of<LyreBloc>(context).state.currentTheme.borderRadius.toDouble();
    return Stack(
      children: <Widget>[
        body,
        Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(borderRadius),
                topRight: Radius.circular(borderRadius),
              ),
              child: Container(
                width: constraints.maxWidth,
                color: Theme.of(context).primaryColor,
                height: kBottomNavigationBarHeight,
                child: appBarContent,
              ),
            )
          ),
        )
      ],
    );
  }
}