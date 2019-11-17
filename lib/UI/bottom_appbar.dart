import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';

class PersistentBottomAppbarWrapper extends StatefulWidget {
  /// The body content
  final Widget child;
  /// The content shown in the appbar itself
  final Widget appBarContent;
  /// The content for the expanding part of the bottom sheet
  final State<ExpandingSheetContent> expandingSheetContent;
  final height = 50.0;
  /// The full expanded height of the expanded bottom sheet
  final double fullSizeHeight;

  const PersistentBottomAppbarWrapper({Key key, @required this.child, @required this.appBarContent, this.expandingSheetContent, @required this.fullSizeHeight}) : super(key: key);

  @override
  State<PersistentBottomAppbarWrapper> createState() => notNull(appBarContent) ? _PersistentBottomAppbarWrapperState() : _PersistentBottomAppBarWrapperStateWithoutExpansion();
}

class _PersistentBottomAppbarWrapperState extends State<PersistentBottomAppbarWrapper> with SingleTickerProviderStateMixin {
  double fullSizeHeight;

  AnimationController _controller;

  ScrollController _innerController;
  bool isInnerScrollDoingDown;

  //start drag position of widget's gesture detector
  Offset startPosition;

  //offset from startPosition within drag event of widget's gesture detector
  double dyOffset;

  //boundaries for height of widget (bottom sheet)
  List<double> heights;

  //current height of widget (bottom sheet)
  double height;

  @override
  void initState() { 
    super.initState();

    heights = [widget.height, widget.fullSizeHeight/2, widget.fullSizeHeight];
    height = heights[0];


    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {});
    });
    _innerController = ScrollController();
    _innerController.addListener(_scrollOffsetChanged);
    isInnerScrollDoingDown = false;
  }

  _lerp(double min, double max) => lerpDouble(min, max, _controller.value);

  @override
  Widget build(BuildContext context) {
    fullSizeHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      onVerticalDragUpdate: (DragUpdateDetails dragDetails) => dyOffset += dragDetails.delta.dy,
      onVerticalDragStart: (DragStartDetails dragDetails) {
        startPosition = dragDetails.globalPosition;
        dyOffset = 0;
      },
      onVerticalDragEnd: (DragEndDetails dragDetails) => _changeHeight(),
      child: Container(
        height: height,
        color: Colors.deepOrange,
        child: ExpandingSheetContent(state: widget.expandingSheetContent, innerController: _innerController, scrollEnabled: _getInnerScrollEnabled(),)        
      ),
    );
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned(
          bottom: 0.0,
          child: Column(children: <Widget>[
            Container(
              constraints: BoxConstraints(maxHeight: _lerp(50.0, 0.0)),
              color: Theme.of(context).canvasColor,
              child: ExpandingSheetContent(state: widget.expandingSheetContent, innerController: _innerController, scrollEnabled: _getInnerScrollEnabled(),)
            ),
            Container(
              constraints: BoxConstraints(maxHeight: _lerp(0.0, widget.fullSizeHeight)),
              color: Theme.of(context).canvasColor,
              child: widget.appBarContent,
            ),
          ],),
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
  void _changeHeight() {
    if(dyOffset < 0) {
      setState(() {
        int curIndex = heights.indexOf(height);
        int newIndex = curIndex+1;
        height = newIndex >= heights.length
            ? heights[curIndex]
            : heights[newIndex];
      });
    } else if (dyOffset > 0) {
      setState(() {
        int curIndex = heights.indexOf(height);
        int newIndex = curIndex-1 ;
        height = newIndex < 0
            ? heights[curIndex]
            : heights[newIndex];
      });
    }
  }
}
class ExpandingSheetContent extends StatefulWidget {
  final State<ExpandingSheetContent> state;
  final bool scrollEnabled;
  final ScrollController innerController;

  ExpandingSheetContent({@required this.state, @required this.scrollEnabled, @required this.innerController});
  @override
  State<ExpandingSheetContent> createState() => state;
}

class testState extends State<ExpandingSheetContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}
class _PersistentBottomAppBarWrapperStateWithoutExpansion extends State<PersistentBottomAppbarWrapper> {

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        widget.child,
        Positioned(
          bottom: 0.0,
          child: Container(
            color: Theme.of(context).canvasColor,
            height: widget.height,
            child: widget.appBarContent,
          ),
        )
      ],
    );
  }
}