import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/credential_loader.dart';
import 'package:lyre/Resources/globals.dart' as prefix0;
import 'package:lyre/Resources/reddit_api_provider.dart';
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
    if (event is ThemeChanged) {
      yield LyreState(
        themeData: lyreThemeData[event.theme],
        settings: state.settings,
        userNames: state.userNames,
        currentUser: state.currentUser,
        readOnly: state.readOnly
      );
    } else if (event is SettingsChanged) {
      yield LyreState(
        themeData: state.themeData,
        settings: event.settings,
        userNames: state.userNames,
        currentUser: state.currentUser,
        readOnly: state.readOnly
      );
    } else if (event is UserChanged) {
      final currentUser = await PostsProvider().logIn(event.userName);
      yield LyreState(
        themeData: state.themeData,
        settings: state.settings,
        userNames: state.userNames,
        currentUser: currentUser,
        readOnly: currentUser == null
      );
    }
  }
}
/// The first LyreState that the application receives when it starts for the first time,
/// aka the splash-screen FutureBuilder
Future<LyreState> getFirstLyreState() async { 
    final prefs = await Hive.openBox('settings');
    final initialTheme = prefs.get(CURRENT_THEME) ?? "";
    prefix0.homeSubreddit = prefs.get(SUBREDDIT_HOME) ?? "askreddit";
    prefix0.currentSubreddit = prefix0.homeSubreddit;
    var _cTheme = LyreTheme.DarkTeal;
    LyreTheme.values.forEach((theme){
      if(theme.toString() == initialTheme){
        _cTheme = theme;
      }
    });
    final userNames = (await getAllUsers()).map<String>((redditUser) => redditUser.username.isEmpty ? "Guest" : redditUser.username).toList();
    print(userNames.length.toString());
    final currentUser = await PostsProvider().logInToLatest();

    return LyreState(
        themeData: lyreThemeData[_cTheme],
        settings: prefs,
        userNames: userNames..insert(0, 'Guest'),
        currentUser: currentUser,
        readOnly: currentUser == null
    );
  }