import 'package:basic_utils/basic_utils.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:meta/meta.dart';

@immutable
class LyreState extends Equatable {
  final ThemeData themeData;
  final bool readOnly;
  final List<String> userNames;
  final Redditor currentUser;

  // * Subscriptions

  final List<String> subscriptions;

  bool isSubscribed (String sub) => subscriptions.contains(StringUtils.capitalize(sub));

  // * Preferences

  final LyreTheme currentTheme;
  final String home;
  final String homeSubreddit;

  final PostView viewMode;
  final bool showPreviewCircle;
  final String defaultSortType;
  final String defaultSortTime;
  final bool resetWhenRefreshingSubmissions;
  final bool autoLoadSubmissions;

  final String defaultCommentsSort;
  final bool precollapseComments;

  final bool enableImageRotation;
  final bool enableVideoRotation;
  final int blurLevel;
  final bool fullSizePreviews;
  final bool loopVideos;
  final bool autoMuteVideos;
  final String imgurThumbnailQuality;
  final int albumColumnPortrait;
  final int albumColumnLandscape;

  final bool showNSFWPreviews;
  final bool showSpoilerPreviews;

  const LyreState({
      @required this.themeData,
      @required this.userNames,
      @required this.currentUser,
      @required this.readOnly,

      @required this.subscriptions,

      @required this.currentTheme,
      @required this.home,
      @required this.homeSubreddit,

      @required this.viewMode,
      @required this.showPreviewCircle,
      @required this.defaultSortType,
      @required this.defaultSortTime,
      @required this.resetWhenRefreshingSubmissions,
      @required this.autoLoadSubmissions,

      @required this.defaultCommentsSort,
      @required this.precollapseComments,

      @required this.enableImageRotation,
      @required this.enableVideoRotation,
      @required this.blurLevel,
      @required this.fullSizePreviews,
      @required this.loopVideos,
      @required this.autoMuteVideos,
      @required this.imgurThumbnailQuality,
      @required this.albumColumnPortrait,
      @required this.albumColumnLandscape,

      @required this.showNSFWPreviews,
      @required this.showSpoilerPreviews,
    });

    @override
    List<dynamic> get props => [themeData, readOnly, userNames, currentUser, subscriptions];
}
