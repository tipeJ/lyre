import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';
import '../themes.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  @override
  ThemeState get initialState => ThemeState(themeData: lyreThemeData[LyreTheme.DarkTeal]);

  @override
  Stream<ThemeState> mapEventToState(
    ThemeEvent event,
  ) async* {
    if(event is ThemeChanged){
      yield ThemeState(themeData: lyreThemeData[event.theme]);
    }
  }
}
