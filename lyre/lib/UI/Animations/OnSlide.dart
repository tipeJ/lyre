import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../ActionItems.dart';
import 'LayoutSizeChangeNotification.dart';
import 'dart:async';

class OnSlide extends StatefulWidget{
  OnSlide({
    Key key,
    @required this.items,
    @required this.child,
    @required this.backgroundColor: Colors.white
  }):super(key: key){
    assert(items.length <= 6);
  }

  final List<ActionItems> items;
  final Widget child;
  final Color backgroundColor;

  @override
  State<StatefulWidget> createState(){
    return new _OnSlideState();
  }
}

class _OnSlideState extends State<OnSlide>{
  ScrollController controller = new ScrollController();
  bool isOpen = false;

  Size childSize;

  @override
  void initState(){
    super.initState();
    controller.addListener(_scrollListener);
  }
  double _opacity = 0.0;

  bool _handleScrollNotification(dynamic notification){
    if(notification is ScrollEndNotification){
      if(notification.metrics.pixels >= (widget.items.length * 70.0)/2 && notification.metrics.pixels < widget.items.length * 70.0){
        scheduleMicrotask((){
          controller.animateTo(widget.items.length * 60.0,duration: new Duration(milliseconds:  600), curve: Curves.decelerate);
        });
      }else if(notification.metrics.pixels > 0.0 && notification.metrics.pixels < (widget.items.length * 70.0)/2){
        scheduleMicrotask((){
          controller.animateTo(0.0, duration: Duration(milliseconds: 600), curve: Curves.decelerate);
        });
      }
      return true;
    }
  }

  _scrollListener(){
    
    if(!controller.position.outOfRange){
      _opacity = (controller.offset / controller.position.maxScrollExtent);
      scheduleMicrotask((){
        setState((){});
      });
    }
  }

  @override
  Widget build(BuildContext context){
    if(childSize == null){
      return new NotificationListener(
        child: new LayoutSizeChangeNotifier(
          child: widget.child,
        ),
        onNotification: (LayoutSizeChangeNotification notification){
          childSize = notification.newSize;
          scheduleMicrotask((){
            setState((){});
          });
        },
      );
    }
    List<Widget> above = <Widget>[new Container(
            width: childSize.width,
            height: childSize.height,
            color: widget.backgroundColor,
            child: widget.child,
        ),];
    List<Widget> under = <Widget>[];

    for (ActionItems item in widget.items){
            under.add(
                new Container(
                    alignment: Alignment.center,
                    color: item.backgroundColor,
                    width: 60.0,
                    height: childSize.height,
                    
                    child: item.icon,
                )
            );

            above.add(
                new InkWell(
                    child: new Container(
                      alignment: Alignment.center,
                      width: 60.0,
                      height: childSize.height,
                    ),
                    onTap: () {
                        controller.jumpTo(2.0);
                        item.onPress();
                    }
                )
            );
        }
    Widget items = Opacity(
      child: new Container(
            width: childSize.width,
            height: childSize.height,
            color: widget.backgroundColor,
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: under,
            ),
        ),
        opacity: _opacity,
    );
    Widget scrollview = new NotificationListener(
            child: new ListView(
                controller: controller,
                scrollDirection: Axis.horizontal,
                children: above,
            ),
            onNotification: _handleScrollNotification,
        );
    return Stack(
        children: <Widget>[
            items,
            new Positioned(child: scrollview, left: 0.0, bottom: 0.0, right: 0.0, top: 0.0,)
        ],
    );
  }

}