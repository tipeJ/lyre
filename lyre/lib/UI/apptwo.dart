import 'package:flutter/material.dart';
import 'posts_list.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: lyApp(),
      ),
    );
  }


}