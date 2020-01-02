import 'dart:async';
import 'package:basic_utils/basic_utils.dart';
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
      final index = state.subscriptions.indexOf(StringUtils.capitalize(event.subreddit));
      //IF element is found, delete the entry from the subscription lists
      if (index != -1) {
        final subList = List<String>();
        subList.addAll(state.subscriptions);
        final subreddit = subList[index];

        subList.removeAt(index);
        yield _changeState(subs: subList);

        final subscriptionsBox = await Hive.openBox(BOX_SUBSCRIPTIONS_PREFIX + (state.currentUser != null ? state.currentUser.displayName.toLowerCase() : ''));
        //Delete the subreddit from the subreddit box.
        final subscriptionsBoxValue = subscriptionsBox.values.toList();
        for (var i = 0; i < subscriptionsBoxValue.length; i++) {
          if (subscriptionsBoxValue[i] == subreddit) {
            subscriptionsBox.deleteAt(i);
            break;
          }
        }
      }
    } else if (event is Subscribe) {
      final subreddit = StringUtils.capitalize(event.subreddit).trim();
      final subList = List<String>();
      subList.addAll(state.subscriptions);
      if (!subList.contains(subreddit)) {
        final subscriptionsBox = await Hive.openBox(BOX_SUBSCRIPTIONS_PREFIX + (state.currentUser != null ? state.currentUser.displayName.toLowerCase() : ''));
        //Delete the subreddit from the subreddit box.
        subList.add(subreddit);
        subscriptionsBox.add(subreddit);
        yield _changeState(subs: subList);
        await subscriptionsBox.close();
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
    final defaultSubscriptions = defaultSubscriptionsFile.split('\n').map((s) => StringUtils.capitalize(s).trim()).toList();
    subscriptions.addAll(defaultSubscriptions);
    subscriptionsBox.addAll(defaultSubscriptions);
  } else {
    //Add the default from the box to the state file.
    subscriptionsBox.values.forEach((value) {
      subscriptions.add((value as String).trim());
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
    final initialTheme = settings.get(CURRENT_THEME, defaultValue: "");
    globals.homeSubreddit = settings.get(SUBREDDIT_HOME, defaultValue: "askreddit");

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

      viewMode: settings.get(SUBMISSION_VIEWMODE, defaultValue: SUBMISSION_VIEWMODE_DEFAULT),
      showPreviewCircle: settings.get(SUBMISSION_PREVIEW_SHOWCIRCLE, defaultValue: SUBMISSION_PREVIEW_SHOWCIRCLE_DEFAULT),
      defaultSortType: settings.get(SUBMISSION_DEFAULT_SORT_TYPE, defaultValue: SUBMISSION_DEFAULT_SORT_TYPE_DEFAULT),
      defaultSortTime: settings.get(SUBMISSION_DEFAULT_SORT_TIME, defaultValue: SUBMISSION_DEFAULT_SORT_TIME_DEFAULT),
      resetWhenRefreshingSubmissions: settings.get(SUBMISSION_RESET_SORTING, defaultValue: SUBMISSION_RESET_SORTING_DEFAULT),
      autoLoadSubmissions: settings.get(SUBMISSION_AUTO_LOAD, defaultValue: SUBMISSION_AUTO_LOAD_DEFAULT),

      defaultCommentsSort: settings.get(COMMENTS_DEFAULT_SORT, defaultValue: COMMENTS_DEFAULT_SORT_DEFAULT),
      precollapseComments: settings.get(COMMENTS_PRECOLLAPSE, defaultValue: COMMENTS_PRECOLLAPSE_DEFAULT),

      enableImageRotation: settings.get(IMAGE_ENABLE_ROTATION, defaultValue: IMAGE_ENABLE_ROTATION_DEFAULT),
      enableVideoRotation: settings.get(VIDEO_ENABLE_ROTATION, defaultValue: VIDEO_ENABLE_ROTATION_DEFAULT),
      blurLevel: settings.get(IMAGE_BLUR_LEVEL, defaultValue: IMAGE_BLUR_LEVEL_DEFAULT),
      fullSizePreviews: settings.get(IMAGE_SHOW_FULLSIZE, defaultValue: IMAGE_SHOW_FULLSIZE_DEFAULT),
      loopVideos: settings.get(VIDEO_LOOP, defaultValue: VIDEO_LOOP_DEFAULT),
      autoMuteVideos: settings.get(VIDEO_AUTO_MUTE, defaultValue: VIDEO_AUTO_MUTE_DEFAULT),
      imgurThumbnailQuality: settings.get(IMGUR_THUMBNAIL_QUALITY, defaultValue: IMGUR_THUMBNAIL_QUALITY_DEFAULT),
      albumColumnPortrait: settings.get(ALBUM_COLUMN_AMOUNT_PORTRAIT),
      albumColumnLandscape: settings.get(ALBUM_COLUMN_AMOUNT_LANDSCAPE),

      showNSFWPreviews: settings.get(SHOW_NSFW_PREVIEWS, defaultValue: SHOW_NSFW_PREVIEWS_DEFAULT),
      showSpoilerPreviews: settings.get(SHOW_SPOILER_PREVIEWS, defaultValue: SHOW_SPOILER_PREVIEWS_DEFAULT),
    );


    //Close the Settings box
    //settings.close();

    return state;
  }