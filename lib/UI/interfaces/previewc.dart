import 'package:flutter/material.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';

class PreviewCall {
  static final PreviewCall _PreviewCall = PreviewCall._internal();

  factory PreviewCall() {
    return _PreviewCall;
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  PreviewCall._internal();

  PreviewCallback callback;
}