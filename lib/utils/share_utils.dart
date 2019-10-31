import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:share/share.dart';

Future<bool> copyToClipboard(String value) {
  return ClipboardManager.copyToClipBoard(value);
}
void shareString(String value){
  Share.share(value);
}