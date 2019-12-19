import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';

Future<bool> copyToClipboard(String value) {
  return ClipboardManager.copyToClipBoard(value);
}
Future<String> getClipBoard() async {
  final clipBoardData = await Clipboard.getData(Clipboard.kTextPlain);
  return clipBoardData.text;
}
//Shares a String value
void shareString(String value){
  Share.share(value);
}