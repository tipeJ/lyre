import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/UI/bottom_appbar_expanding.dart';
import 'package:lyre/UI/bottom_appbar_expanding.dart' as prefix0;

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

  final bool showShadow = true;

  const PersistentBottomAppbarWrapper({Key key, @required this.body, @required this.appBarContent, this.expandingSheetContent, @required this.fullSizeHeight}) : super(key: key);

  @override
  State<PersistentBottomAppbarWrapper> createState() => notNull(expandingSheetContent) ? _PersistentBottomAppbarWrapperState() : _PersistentBottomAppBarWrapperStateWithoutExpansion();
}

class _PersistentBottomAppbarWrapperState extends State<PersistentBottomAppbarWrapper> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  ScrollController _innerController;
  bool isInnerScrollDoingDown;

  ExpandingAppbarController _appbarController;

  @override
  void initState() { 
    super.initState();

    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 325));
    _controller.addListener(() {
      setState(() {});
    });
    _appbarController = ExpandingAppbarController(expansionController: _controller);
    _innerController =  ScrollController();
    _innerController.addListener(_scrollOffsetChanged);
    isInnerScrollDoingDown = false;

  }

  _lerp(double min, double max) => lerpDouble(min, max, _controller.value);

  @override
  void dispose() { 
    _controller.dispose();
    _innerController.dispose();
    _appbarController.dispose();
    super.dispose();
  }
  Future<bool> _willPop() {
    if (_controller.value > 0.9) {
      _controller.animateTo(0.0, curve: Curves.ease);
      return Future.value(false);
    }
    return Future.value(true);
  }

  void _setExtent() {
    setState(() {
      
    });
  }
  final x = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.body,
        Align(
          alignment: Alignment.bottomCenter,
          child: x ?prefix0.DraggableScrollableSheet(
              expand: true,
              maxChildSize: 1,
              minChildSize: 56 / MediaQuery.of(context).size.height,
              initialChildSize: 56 / MediaQuery.of(context).size.height,
              builder: (context, scontrol) {
                return ExpandingSheetContent(state: widget.expandingSheetContent, innerController: scontrol, appBarContent: widget.appBarContent,);
              },
            )
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
      ],
    );
  }
  void _scrollOffsetChanged(){
    if (_innerController.offset < 0.0) {
      isInnerScrollDoingDown = true;
    } else if (_innerController.offset > 0.0){
      isInnerScrollDoingDown = false;
    }

    if (_innerController.offset <= 0.0) {
      setState(() {});
    }
  }
  void _changeHeight(DragEndDetails details) {
    if (_controller.isAnimating ||
        _controller.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy / widget.fullSizeHeight; //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      _controller.fling(
        velocity: max(2.0, -flingVelocity)); //<-- either continue it upwards
    } else if (flingVelocity > 0.0) {
      _controller.fling(
        velocity: min(-2.0, -flingVelocity)); //<-- or continue it downwards
    } else
      _controller.fling(
        velocity: _controller.value < 0.5
          ? -2.0
          : 2.0); //<-- or just continue to whichever edge is closer
  }
}
class ExpandingAppbarController extends ChangeNotifier {
  final AnimationController expansionController;

  bool expanded() => expansionController.value == 1.0;

  ExpandingAppbarController({@required this.expansionController});
}
class ExpandingSheetContent extends StatefulWidget {
  final State<ExpandingSheetContent> state;
  final Widget appBarContent;
  final DraggableScrollableSheetScrollController innerController;

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
          child: Container(
            width: MediaQuery.of(context).size.width,
            color: Theme.of(context).canvasColor,
            height: widget.height,
            child: widget.appBarContent,
          ),
        )
      ],
    );
  }
}