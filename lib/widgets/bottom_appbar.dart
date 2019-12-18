import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/widgets/bottom_appbar_expanding.dart' as prefix0;

///Class for wrapping a scaffold body for a custom bottom expanding appBar
class PersistentBottomAppbarWrapper extends StatefulWidget {
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
  State<PersistentBottomAppbarWrapper> createState() => notNull(expandingSheetContent) ? _PersistentBottomAppbarWrapperState() : _PersistentBottomAppBarWrapperStateWithoutExpansion();
}

class _PersistentBottomAppbarWrapperState extends State<PersistentBottomAppbarWrapper> {

  @override
  void initState() { 
    super.initState();
    widget.listener?.addListener(() {
      setState(() {
        
      });
    });
  }

  bool get _visible => widget.listener != null ? widget.listener.value : true;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          widget.body,
          IgnorePointer(
            ignoring: !_visible,
            child: Align(
              alignment: Alignment.bottomCenter,
              //Expandable appbar
              child: AnimatedContainer(
                duration: Duration(milliseconds: 800),
                // ? Could possibly be more elegant. Currently switches between fullsizeHeight and 0, instead of default appbar height and 0
                height: _visible ? widget.fullSizeHeight : 0.0,
                curve: Curves.ease,
                child: prefix0.DraggableScrollableSheet(
                    expand: true,
                    maxChildSize: MediaQuery.of(context).size.height,
                    minChildSize: kBottomNavigationBarHeight,
                    initialChildSize: kBottomNavigationBarHeight,
                    builder: (context, scontrol) {
                      return ExpandingSheetContent(state: widget.expandingSheetContent, innerController: scontrol, appBarContent: widget.appBarContent,);
                    },
                  )
                )
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
  final prefix0.DraggableScrollableSheetScrollController innerController;
  final ValueNotifier<bool> visible = ValueNotifier(true);

  ExpandingSheetContent({@required this.state, @required this.innerController, @required this.appBarContent});
  @override
  State<ExpandingSheetContent> createState() => state;
}
class _PersistentBottomAppBarWrapperStateWithoutExpansion extends State<PersistentBottomAppbarWrapper> {

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.body,
        Positioned(
          bottom: 0.0,
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15.0),
              topRight: Radius.circular(15.0),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Theme.of(context).canvasColor,
              height: kBottomNavigationBarHeight,
              child: widget.appBarContent,
            ),
          ),
        )
      ],
    );
  }
}