import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/UI/Comments/comment_list.dart';
import 'package:lyre/UI/Preferences.dart';
import 'package:lyre/UI/Router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'posts_list.dart';
import 'submit.dart';
import '../Resources/globals.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, AsyncSnapshot<SharedPreferences> snapshot){
        if(snapshot.hasData){
          final prefs = snapshot.data;
          return BlocProvider(
            builder: (context) => ThemeBloc(snapshot.data.get('currentTheme') == null ? "" : snapshot.data.get('currentTheme')),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: _buildWithTheme,
            ),
          );
        }else{
          return Container(
            width: 25.0,
            height: 25.0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
  Widget _buildWithTheme(BuildContext context, ThemeState themeState){
    return MaterialApp(
      title: 'Lyre',
      theme: themeState.themeData,
      initialRoute: 'posts',
      onGenerateRoute: Router.generateRoute,
    );
  }


}