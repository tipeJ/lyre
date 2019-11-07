import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';
import '../themes.dart';

class LyreBloc extends Bloc<LyreEvent, LyreState> {
  final LyreState _initialS;
  /*
  LyreTheme getInitialTheme(){
    var cTheme = LyreTheme.DarkTeal;
    LyreTheme.values.forEach((theme){
      if(theme.toString() == initialTheme){
        cTheme = theme;
      }
    });
    return cTheme;
  }
*/
  LyreBloc(this._initialS);

  @override
  LyreState get initialState => _initialS;

  @override
  Stream<LyreState> mapEventToState(
    LyreEvent event,
  ) async* {
    if(event is ThemeChanged){
      yield LyreState(
        themeData: lyreThemeData[event.theme],
        settings: state.settings
        );
    } else if (event is SettingsChanged) {
      yield LyreState(
        themeData: state.themeData,
        settings: event.settings
      );
    }
  }
}