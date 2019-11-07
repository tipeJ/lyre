import 'package:flutter/material.dart';

class LyreTextStyles {
  static final LyreTextStyles _instance = new LyreTextStyles._internal();
  LyreTextStyles._internal();

  factory LyreTextStyles(){
    return _instance;
  }

  static const errorMessage = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold
  );
}
