import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';

class PersistentBottomAppbarWrapper extends StatefulWidget {
  /// The body content
  final Widget body;
  /// The content shown in the appbar itself
  final Widget appBarContent;
  /// The content for the expanding part of the bottom sheet
  final State<ExpandingSheetContent> expandingSheetContent;
  final height = 75.0;
  /// The full expanded height of the expanded bottom sheet
  final double fullSizeHeight;

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
    _innerController = ScrollController();
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
    print('received');
    if (_controller.value > 0.9) {
      _controller.animateTo(0.0, curve: Curves.ease);
      return Future.value(false);
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.body,
        Positioned(
          bottom: 0.0,
          child: GestureDetector(
            onVerticalDragUpdate: (DragUpdateDetails details) => _controller.value -= details.primaryDelta / widget.fullSizeHeight, //<-- Update the _controller.value by the movement done by user.
            onVerticalDragEnd: _changeHeight,
            child: Column(children: <Widget>[
              Container(
                constraints: BoxConstraints(maxHeight: _lerp(widget.height, 0.0)),
                decoration: BoxDecoration(
                  color: Theme.of(context).canvasColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(_lerp(15.0, 0.0)),
                    topRight: Radius.circular(_lerp(15.0, 0.0)),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12.0,
                      spreadRadius: 5.0,
                      offset: Offset(0.0, -2.5)
                    )
                  ]
                ),
                child: widget.appBarContent
              ),
              Container(
                height: _lerp(0.0, widget.fullSizeHeight),
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).canvasColor,
                child: ExpandingSheetContent(state: widget.expandingSheetContent, scrollEnabled: _getInnerScrollEnabled(), innerController: _innerController, appbarController: _appbarController,)
              ),
            ],),
          ),
        )
      ],
    );
  }
  bool _getInnerScrollEnabled(){
    bool isFullSize = _controller.value == 1.0;
    bool isScrollZeroOffset = _innerController.hasClients ? _innerController.offset == 0.0 && isInnerScrollDoingDown: false;
    bool result = isFullSize && !isScrollZeroOffset;

    //reset isInnerScrollDoingDown
    if(!result) isInnerScrollDoingDown = false;
    return result;
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
  final bool scrollEnabled;
  final ScrollController innerController;
  final ExpandingAppbarController appbarController;

  ExpandingSheetContent({@required this.state, @required this.scrollEnabled, @required this.innerController, @required this.appbarController});
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
            constraints: BoxConstraints(maxHeight: widget.height),
            child: widget.appBarContent,
          ),
        )
      ],
    );
  }
}