import 'package:flutter/material.dart';

class ActionItems extends Object{
  ActionItems({
    @required this.icon,
    @required this.onPress,
    this.backgroundColor: Colors.grey
  }){
    assert(icon != null);
    assert(onPress != null);
  }

  final Widget icon;
  final VoidCallback onPress;
  final Color backgroundColor;
}