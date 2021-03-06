library lyre.globals;
import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'reddit_api_provider.dart';
part 'globals.g.dart';

const WIKI_SIDEBAR_ARGUMENTS = "config/sidebar";
const FRONTPAGE_TARGET = "_";

const SUBREDDITS_BASE_URL = "https://www.reddit.com/subreddits/";
const SEARCH_BASE_URL = "https://www.reddit.com/search.json";

const REDDIT_ICON_DEFAULT = "https://icons-for-free.com/iconfiles/png/512/reddit+website+icon-1320168605279647340.png";

// * Client IDs

const GFYCAT_GET_URL = "https://api.gfycat.com/v1/gfycats/";
const GFYCAT_CLIENT_ID = "2__lD9Ci";
const GFYCAT_CLIENT_SECRET = "waadJXMtWmfHC45OeMvE9lDrKkhQ9XCR0xLMbaFTuINQPjd4s0mcrnnBN8cMmuAr";

const TWITCH_CLIENT_ID = 'kimne78kx3ncx6brgo4mv6wki5h1ko';

const GOOGLE_IMAGE_SEARCH_BASE_URL = "https://images.google.com/searchbyimage?image_url=";

const FRONTPAGE_HOME_SUB = "_";

const appBarContentTransitionDuration = Duration(milliseconds: 250);

/// The width of the separator between the main window and the details window.
/// Used in Peek's and dual layout (for example, tablet layout for comments_list)
const screenSplitterWidth = 3.5;


String homeSubreddit;

enum LoadingState {
  Inactive,
  Error,
  LoadingMore,
  Refreshing,
}

@HiveType(typeId: 0, adapterName: "PostsViewAdapter")
enum PostView{
  @HiveField(0)
  ImagePreview,
  @HiveField(1)
  IntendedPreview,
  @HiveField(2)
  Compact,
  @HiveField(3)
  NoPreview
}
const List<String> PostViewTitles = [
  "Image Preview",
  "Intended Image Preview",
  "Compact",
  "No Preview"
];

const List<String> sortTypes = [
  "hot",
  "new",
  "rising",
  "top",
  "controversial",
];
const List<String> sortTypesuser = [
  "hot",
  "new",
  "top",
  "controversial",
];
const List<String> sortTimes = [
  "hour",
  "24h",
  "week",
  "month",
  "year",
  "all time"
];
const List<String> commentSortTypes = [
  "Best",
  "Confidence",
  "Controversial",
  "New",
  "Old",
  "Q/A",
  "Random",
  "Top",
  "Blank"
];
const List<IconData> commentsSortIcons = [
  MdiIcons.medal,
  MdiIcons.handOkay,
  MdiIcons.swordCross,
  MdiIcons.newBox,
  MdiIcons.clock,
  MdiIcons.accountQuestion,
  MdiIcons.commentQuestion,
  MdiIcons.trophy,
  MdiIcons.timerSandEmpty
];
IconData getCommentsSortIcon(String type) {
  switch (type) {
    // * Type sort icons:
    case 'Confidence':
      return MdiIcons.handOkay;
    case 'Top':
      return MdiIcons.trophy;
    case 'New':
      return MdiIcons.newBox;
    case 'Controversial':
      return MdiIcons.swordCross;
    case 'Old':
      return MdiIcons.clock;
    case 'Random':
      return MdiIcons.commentQuestion;
    case 'Q/A':
      return MdiIcons.accountQuestion;
    default:
      //Defaults to best
      return MdiIcons.medal;
  }
}

enum SendingState {
  Sending,
  Inactive,
  Error
}

ContentSource currentContentSource = ContentSource.Subreddit;

const TypeFilter defaultSortType = TypeFilter.Hot;
final String defaultSortTime = sortTimes[1];

TypeFilter parseTypeFilter(String typeFilter){
  switch (typeFilter) {
    case 'hot':
      return TypeFilter.Hot;
      break;
    case 'new':
      return TypeFilter.New;
      break;
    case 'rising':
      return TypeFilter.Rising;
      break;
    case 'top':
      return TypeFilter.Top;
      break;
    case 'controversial':
      return TypeFilter.Controversial;
      break;
    
    default:
  }
}

bool notNull(Object o) => o != null;

extension nonNull on List {

  List nonNulls() {
    return this.where((w) => notNull(w)).toList();
  }
}

const String appName = "Lyre";
const String appVersion = "0.2";

const String youtubeApiKey = "ENTER_YT_API_KEY_HERE";

const int perPage = 25;

List<Submission> recentlyViewed = [];

// * String constants
const clipBoardErrorMessage = "Clipboard is not Available";
const noConnectionErrorMessage = "No Internet Connection.";