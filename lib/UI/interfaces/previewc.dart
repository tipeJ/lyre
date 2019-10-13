import 'package:lyre/UI/interfaces/previewCallback.dart';

class PreviewCall {
  static final PreviewCall _PreviewCall = PreviewCall._internal();

  factory PreviewCall() {
    return _PreviewCall;
  }

  PreviewCall._internal();

  PreviewCallback callback;
}