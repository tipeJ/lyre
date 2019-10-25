import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/UI/apptwo.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  Hive.registerAdapter(PostViewAdapter(), 0);
  runApp(new App());
}