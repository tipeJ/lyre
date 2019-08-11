import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';
import '../themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final String initialTheme;

  LyreTheme getInitialTheme(){
    var cTheme = LyreTheme.DarkTeal;
    LyreTheme.values.forEach((theme){
      if(theme.toString() == initialTheme){
        cTheme = theme;
      }
    });
    return cTheme;
  }

  ThemeBloc(this.initialTheme);

  @override
  ThemeState get initialState => ThemeState(themeData: lyreThemeData[getInitialTheme()]);

  @override
  Stream<ThemeState> mapEventToState(
    ThemeEvent event,
  ) async* {
    if(event is ThemeChanged){
      yield ThemeState(themeData: lyreThemeData[event.theme]);
    }
  }
}
