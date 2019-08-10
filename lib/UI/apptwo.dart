import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'posts_list.dart';
import 'submit.dart';
import '../Resources/globals.dart';
import 'comments_list.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      builder: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: _buildWithTheme,
      ),
    );
  }
  Widget _buildWithTheme(BuildContext context, ThemeState themeState){
    return MaterialApp(
      title: 'Lyre',
      theme: themeState.themeData,
      routes: {
        '/': (context) => PostsView(""),
        '/comments': (context) => commentsList(cPost),
        '/submit': (context) => SubmitWindow(),
      },
    );
  }


}