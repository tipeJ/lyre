import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
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

  final ValueNotifier<bool> listener;

  const PersistentBottomAppbarWrapper({Key key, @required this.body, this.appBarContent, this.expandingSheetContent, this.fullSizeHeight, this.listener}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return expandingSheetContent != null
      ? _ExpandingBottomAppWrapper(
        body: body,
        appBarContent: appBarContent,
        expandingSheetContent: expandingSheetContent,
        visibilityListener: listener,
      )
      : _PersistentBottomAppWrapperWithoutExpansion(
        body: body,
        appBarContent: appBarContent,
      );
  }
}

class _ExpandingBottomAppWrapper extends StatelessWidget{

  final Widget body;
  final Widget appBarContent;
  final State<ExpandingSheetContent> expandingSheetContent;
  final ValueNotifier<bool> visibilityListener;

  const _ExpandingBottomAppWrapper({
    @required this.body,
    @required this.expandingSheetContent,
    @required this.appBarContent,
    @required this.visibilityListener
  }) : 
    assert(body != null),
    assert(appBarContent != null),
    assert(expandingSheetContent != null),
    assert(visibilityListener != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          body,
          Align(
              alignment: Alignment.bottomCenter,
              //Expandable appbar
              child: prefix0.LyreDraggableScrollableSheet(
                expand: true,
                visible: visibilityListener,
                maxChildSize: MediaQuery.of(context).size.height,
                minChildSize: kBottomNavigationBarHeight,
                borderRadius: BlocProvider.of<LyreBloc>(context).state.currentTheme.borderRadius.toDouble(),
                initialChildSize: kBottomNavigationBarHeight,
                builder: (context, scontrol) {
                  return ExpandingSheetContent(state: expandingSheetContent, innerController: scontrol, appBarContent: appBarContent);
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
  final Widget appBarContent;
  final prefix0.LyreDraggableScrollableSheetScrollController innerController;
  final ValueNotifier<bool> visible = ValueNotifier(true);

  ExpandingSheetContent({@required this.state, @required this.innerController, @required this.appBarContent});
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
        Positioned(
          bottom: 0.0,
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Theme.of(context).primaryColor,
              height: kBottomNavigationBarHeight,
              child: appBarContent,
            ),
          ),
        )
      ],
    );
  }
}