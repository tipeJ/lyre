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

  static const title = TextStyle(fontSize: 35.0);

  static const dialogTitle = TextStyle(fontSize: 24.0);

  static const typeParams = TextStyle(fontSize: 26.0);
  static const timeParams = TextStyle(fontSize: 13.0);
  static const iconText = TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500);
}