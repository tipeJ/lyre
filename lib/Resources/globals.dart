library lyre.globals;
import 'package:draw/draw.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'reddit_api_provider.dart';
part 'globals.g.dart';

String WIKI_SIDEBAR_ARGUMENTS = "config/sidebar";

String SUBREDDITS_BASE_URL = "https://www.reddit.com/subreddits/";

String GFYCAT_GET_URL = "https://api.gfycat.com/v1/gfycats/";
String GFYCAT_CLIENT_ID = "2__lD9Ci";
String GFYCAT_CLIENT_SECRET = "waadJXMtWmfHC45OeMvE9lDrKkhQ9XCR0xLMbaFTuINQPjd4s0mcrnnBN8cMmuAr";

String currentSubreddit = "nocontextpics";
String homeSubreddit;

@HiveType(adapterName: "PostViewAdapter")
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

List<String> subreddits = [
  "popular",
  "all",
  "announcements",
  "funny",
  "AskReddit",
  "gaming",
  "pics",
  "science",
  "worldnews",
  "aww",
  "movies",
  "todayilearned",
  "videos",
  "Music",
  "IAmA",
  "news",
  "gifs",
  "EarthPorn",
  "Showerthoughts",
  "askscience",
  "blog",
  "Jokes",
  "explainlikeimfive",
  "books",
  "food",
  "LifeProTips",
  "DIY",
  "mildlyinteresting",
  "Art",
  "sports",
  "space",
  "gadgets",
];

List<String> sortTypes = [
  "hot",
  "new",
  "rising",
  "top",
  "controversial",
];
List<String> sortTypesuser = [
  "hot",
  "new",
  "top",
  "controversial",
];
List<String> sortTimes = [
  "hour",
  "24h",
  "week",
  "month",
  "year",
  "all time"
];
List<String> commentSortTypes = [
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

ContentSource currentContentSource = ContentSource.Subreddit;

final TypeFilter defaultSortType = TypeFilter.Hot;
final String defaultSortTime = sortTimes[1];

TypeFilter currentSortType = defaultSortType;
String currentSortTime = "";

void parseTypeFilter(String typeFilter){
  switch (typeFilter) {
    case 'hot':
      currentSortType = TypeFilter.Hot;
      break;
    case 'new':
      currentSortType = TypeFilter.New;
      break;
    case 'rising':
      currentSortType = TypeFilter.Rising;
      break;
    case 'top':
      currentSortType = TypeFilter.Top;
      break;
    case 'controversial':
      currentSortType = TypeFilter.Controversial;
      break;
    
    default:
  }
}

String currentPostId = "";
bool notNull(Object o) => o != null;

String appName = "Lyre";
String appVersion = "0.1";

String youtubeApiKey = "ENTER_YT_API_KEY_HERE";

int perPage = 25;
int currentCount = 0;
String lastPost = "";

bool preCollapsed = false;

List<Submission> recentlyViewed = [];