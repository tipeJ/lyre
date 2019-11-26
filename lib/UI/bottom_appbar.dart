import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/UI/bottom_appbar_expanding.dart' as prefix0;

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

  const PersistentBottomAppbarWrapper({Key key, @required this.body, @required this.appBarContent, this.expandingSheetContent, @required this.fullSizeHeight, this.listener}) : super(key: key);

  @override
  State<PersistentBottomAppbarWrapper> createState() => notNull(expandingSheetContent) ? _PersistentBottomAppbarWrapperState() : _PersistentBottomAppBarWrapperStateWithoutExpansion();
}

class _PersistentBottomAppbarWrapperState extends State<PersistentBottomAppbarWrapper> with SingleTickerProviderStateMixin {

  @override
  void initState() { 
    super.initState();
    widget.listener.addListener(() {
      setState(() {
        
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          widget.body,
          IgnorePointer(
            ignoring: !widget.listener.value,
            child: Align(
              alignment: Alignment.bottomCenter,
              //Expandable appbar
              child: AnimatedContainer(
                duration: Duration(milliseconds: 800),
                // ? Could possibly be more elegant. Currently switches between fullsizeHeight and 0, instead of default appbar height and 0
                height: widget.listener.value ? widget.fullSizeHeight : 0.0,
                curve: Curves.ease,
                child: widget.expandingSheetContent != null 
                  ? prefix0.DraggableScrollableSheet(
                    expand: true,
                    maxChildSize: 1,
                    minChildSize: 56 / MediaQuery.of(context).size.height,
                    initialChildSize: 56 / MediaQuery.of(context).size.height,
                    builder: (context, scontrol) {
                      return ExpandingSheetContent(state: widget.expandingSheetContent, innerController: scontrol, appBarContent: widget.appBarContent,);
                    },
                  )
                  //Static appbar
                  : Container(
                    child: widget.appBarContent,
                    constraints: BoxConstraints(maxHeight: 56.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).canvasColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.38),
                          blurRadius: 12.0,
                          spreadRadius: 5.0,
                          offset: Offset(0.0, -2.5)
                        )
                      ]
                    ),
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
              height: widget.height,
              child: widget.appBarContent,
            ),
          ),
        )
      ],
    );
  }
}