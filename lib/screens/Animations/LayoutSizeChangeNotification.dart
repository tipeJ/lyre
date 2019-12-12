import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef void SizeChangedCallback(Size newSize);

class LayoutSizeChangeNotification extends LayoutChangedNotification{
  LayoutSizeChangeNotification(this.newSize):super();
  Size newSize;
}

class LayoutSizeChangeNotifier extends SingleChildRenderObjectWidget{
  const LayoutSizeChangeNotifier({
    Key key,
    Widget child
  }) : super(key: key, child: child);

  @override
  _SizeChangeRenderWithCallback createRenderObject(BuildContext context){
    return new _SizeChangeRenderWithCallback(
      onLayoutChangedCallback: (size){
        new LayoutSizeChangeNotification(size).dispatch(context);
      }
    );
  }
}

class _SizeChangeRenderWithCallback extends RenderProxyBox{
  _SizeChangeRenderWithCallback({
    RenderBox child,
    @required this.onLayoutChangedCallback
  }) : assert(onLayoutChangedCallback != null), super(child);

  final SizeChangedCallback onLayoutChangedCallback;

  Size _oldSize;

  @override
  void performLayout(){
    super.performLayout();

    if(size != _oldSize)
      onLayoutChangedCallback(size);

    _oldSize = size;
  }
}