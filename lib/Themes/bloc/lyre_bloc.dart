import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/credential_loader.dart';
import 'package:lyre/Resources/globals.dart' as globals;
import 'package:lyre/Resources/reddit_api_provider.dart';
import './bloc.dart';
import '../themes.dart';

class LyreBloc extends Bloc<LyreEvent, LyreState> {
  final LyreState _initialState;
  LyreBloc(this._initialState);

  @override
  LyreState get initialState => _initialState;

  @override
  Stream<LyreState> mapEventToState(
    LyreEvent event,
  ) async* {
    if (event is ThemeChanged) {
      yield _changeState(themeData: lyreThemeData[event.theme]);
    } else if (event is SettingsChanged) {
      final Box settings = event.settings;
      yield LyreState(
        themeData: state.themeData,
        userNames: state.userNames,
        currentUser: state.currentUser,
        readOnly: state.readOnly,

        subscriptions: state.subscriptions,

        currentTheme: settings.get(CURRENT_THEME),
        homeSubreddit: settings.get(SUBREDDIT_HOME),

        viewMode: settings.get(SUBMISSION_VIEWMODE),
        showPreviewCircle: settings.get(SUBMISSION_PREVIEW_SHOWCIRCLE),
        defaultSortType: settings.get(SUBMISSION_DEFAULT_SORT_TYPE),
        defaultSortTime: settings.get(SUBMISSION_DEFAULT_SORT_TIME),
        resetWhenRefreshingSubmissions: settings.get(SUBMISSION_RESET_SORTING),
        autoLoadSubmissions: settings.get(SUBMISSION_AUTO_LOAD),

        defaultCommentsSort: settings.get(COMMENTS_DEFAULT_SORT),
        precollapseComments: settings.get(COMMENTS_PRECOLLAPSE),

        enableImageRotation: settings.get(IMAGE_ENABLE_ROTATION),
        enableVideoRotation: settings.get(VIDEO_ENABLE_ROTATION),
        blurLevel: settings.get(IMAGE_BLUR_LEVEL),
        fullSizePreviews: settings.get(IMAGE_SHOW_FULLSIZE),
        loopVideos: settings.get(VIDEO_LOOP),
        autoMuteVideos: settings.get(VIDEO_AUTO_MUTE),
        imgurThumbnailQuality: settings.get(IMGUR_THUMBNAIL_QUALITY),
        albumColumnPortrait: settings.get(ALBUM_COLUMN_AMOUNT_PORTRAIT),
        albumColumnLandscape: settings.get(ALBUM_COLUMN_AMOUNT_LANDSCAPE),

        showNSFWPreviews: settings.get(SHOW_NSFW_PREVIEWS),
        showSpoilerPreviews: settings.get(SHOW_SPOILER_PREVIEWS),
      );
    } else if (event is UserChanged) {
      final currentUser = await PostsProvider().logIn(event.userName);
      final usernames = await readUsernames();
      final subscriptions = await _getUserSubscriptions(currentUser.displayName);
      yield(_changeState(
        currentUser: currentUser,
        userNames: usernames,
        subs: subscriptions
      ));
    } else if (event is UnSubscribe) {
      final subList = state.subscriptions;
      final index = subList.indexOf(event.subreddit);
      if (index != -1) {
        final subscriptionsBox = await Hive.openBox(BOX_SUBSCRIPTIONS_PREFIX + (state.currentUser != null ? state.currentUser.displayName.toLowerCase() : ''));
        //Delete the subreddit from the subreddit box.
        subList.removeAt(index);
        subscriptionsBox.deleteAt(index);
        yield _changeState(subs: subList);
      }
    } else if (event is Subscribe) {
      if (!state.subscriptions.contains(event.subreddit)) {
        final subscriptionsBox = await Hive.openBox(BOX_SUBSCRIPTIONS_PREFIX + (state.currentUser != null ? state.currentUser.displayName.toLowerCase() : ''));
        //Delete the subreddit from the subreddit box.
        state.subscriptions.add(event.subreddit);
        subscriptionsBox.add(event.subreddit);
        yield _changeState(subs: state.subscriptions);
      }
    }
  }
  LyreState _changeState({List<String> userNames, Redditor currentUser, ThemeData themeData, List<String> subs}) {
    return LyreState(
      themeData: themeData ?? state.themeData,
      userNames: userNames ?? state.userNames,
      currentUser: currentUser ?? state.currentUser,
      readOnly: currentUser == null,

      subscriptions: subs ?? state.subscriptions,

      currentTheme: state.currentTheme,
      homeSubreddit: state.homeSubreddit,

      viewMode: state.viewMode,
      showPreviewCircle: state.showPreviewCircle,
      defaultSortType: state.defaultSortType,
      defaultSortTime: state.defaultSortTime,
      resetWhenRefreshingSubmissions: state.resetWhenRefreshingSubmissions,
      autoLoadSubmissions: state.autoLoadSubmissions,

      defaultCommentsSort: state.defaultCommentsSort,
      precollapseComments: state.precollapseComments,

      enableImageRotation: state.enableImageRotation,
      enableVideoRotation: state.enableVideoRotation,
      blurLevel: state.blurLevel,
      fullSizePreviews: state.fullSizePreviews,
      loopVideos: state.loopVideos,
      autoMuteVideos: state.autoMuteVideos,
      imgurThumbnailQuality: state.imgurThumbnailQuality,
      albumColumnPortrait: state.albumColumnPortrait,
      albumColumnLandscape: state.albumColumnLandscape,

      showNSFWPreviews: state.showNSFWPreviews,
      showSpoilerPreviews: state.showSpoilerPreviews,
    );
  }
}

Future<List<String>> _getUserSubscriptions(String displayName) async {
  final subscriptionsBox = await Hive.openBox(BOX_SUBSCRIPTIONS_PREFIX + displayName.toLowerCase());
  List<String> subscriptions = [];
  if (subscriptionsBox.isEmpty) {
    //Load the asset file where the default subscriptions are stored.
    final defaultSubscriptionsFile = await rootBundle.loadString(DEFAULT_SUBSCRIPTIONS_FILEPATH);
    //Add default subscriptions from the asset file, splitting the string by line breaks.
    final defaultSubscriptions = defaultSubscriptionsFile.split('\n');
    subscriptions.addAll(defaultSubscriptions);
    subscriptionsBox.addAll(defaultSubscriptions);
  } else {
    //Add the default from the box to the state file.
    subscriptionsBox.values.forEach((value) {
      subscriptions.add(value as String);
    });
  }

  //Close the SubscriptionBox
  await subscriptionsBox.close();

  return subscriptions;
}
/// The first LyreState that the application receives when it starts for the first time,
/// aka the splash-screen FutureBuilder
Future<LyreState> getFirstLyreState() async { 
    final settings = await Hive.openBox('settings');
    final initialTheme = settings.get(CURRENT_THEME) ?? "";
    globals.homeSubreddit = settings.get(SUBREDDIT_HOME) ?? "askreddit";

    var _cTheme = LyreTheme.DarkTeal;
    LyreTheme.values.forEach((theme){
      if(theme.toString() == initialTheme){
        _cTheme = theme;
      }
    });

    final userNames = (await getAllUsers()).map<String>((redditUser) => redditUser.username.isEmpty ? "Guest" : redditUser.username).toList();
    final currentUser = await PostsProvider().logInToLatest();
    
    //Empty username for guest
    final subscriptions = await _getUserSubscriptions(currentUser != null ? currentUser.displayName : '');


    final state = LyreState(
      themeData: lyreThemeData[_cTheme],
      userNames: userNames..insert(0, 'Guest'),
      currentUser: currentUser,
      readOnly: currentUser == null,

      subscriptions: subscriptions,

      currentTheme: _cTheme,
      homeSubreddit: globals.homeSubreddit,

      viewMode: settings.get(SUBMISSION_VIEWMODE),
      showPreviewCircle: await settings.get(SUBMISSION_PREVIEW_SHOWCIRCLE),
      defaultSortType: settings.get(SUBMISSION_DEFAULT_SORT_TYPE),
      defaultSortTime: settings.get(SUBMISSION_DEFAULT_SORT_TIME),
      resetWhenRefreshingSubmissions: settings.get(SUBMISSION_RESET_SORTING),
      autoLoadSubmissions: settings.get(SUBMISSION_AUTO_LOAD),

      defaultCommentsSort: settings.get(COMMENTS_DEFAULT_SORT),
      precollapseComments: settings.get(COMMENTS_PRECOLLAPSE),

      enableImageRotation: settings.get(IMAGE_ENABLE_ROTATION),
      enableVideoRotation: settings.get(VIDEO_ENABLE_ROTATION),
      blurLevel: settings.get(IMAGE_BLUR_LEVEL),
      fullSizePreviews: settings.get(IMAGE_SHOW_FULLSIZE),
      loopVideos: settings.get(VIDEO_LOOP),
      autoMuteVideos: settings.get(VIDEO_AUTO_MUTE),
      imgurThumbnailQuality: settings.get(IMGUR_THUMBNAIL_QUALITY),
      albumColumnPortrait: settings.get(ALBUM_COLUMN_AMOUNT_PORTRAIT),
      albumColumnLandscape: settings.get(ALBUM_COLUMN_AMOUNT_LANDSCAPE),

      showNSFWPreviews: settings.get(SHOW_NSFW_PREVIEWS),
      showSpoilerPreviews: settings.get(SHOW_SPOILER_PREVIEWS),
    );


    //Close the Settings box
    //settings.close();

    return state;
  }