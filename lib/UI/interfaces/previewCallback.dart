import 'package:lyre/utils/urlUtils.dart';

abstract class PreviewCallback{
  void preview(String u);
  void view(String u);
  void previewEnd();
}