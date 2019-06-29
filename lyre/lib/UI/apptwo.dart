import 'package:flutter/material.dart';
import 'posts_list.dart';
import 'submit.dart';
import '../Resources/globals.dart';
import 'comments_list.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      initialRoute: '/',
      theme: ThemeData.dark(),
      routes: {
        '/': (context) => lyApp(),
        '/comments': (context) => commentsList(cPost),
        '/submit': (context) => SubmitWindow(),
      },
    );
  }


}