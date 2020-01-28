library lyre.globals;
import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'reddit_api_provider.dart';
part 'globals.g.dart';

const WIKI_SIDEBAR_ARGUMENTS = "config/sidebar";
const FRONTPAGE_TARGET = "_";

const SUBREDDITS_BASE_URL = "https://www.reddit.com/subreddits/";
const SEARCH_BASE_URL = "https://www.reddit.com/search.json";

// * Client IDs

const GFYCAT_GET_URL = "https://api.gfycat.com/v1/gfycats/";
const GFYCAT_CLIENT_ID = "2__lD9Ci";
const GFYCAT_CLIENT_SECRET = "waadJXMtWmfHC45OeMvE9lDrKkhQ9XCR0xLMbaFTuINQPjd4s0mcrnnBN8cMmuAr";

const TWITCH_CLIENT_ID = 'kimne78kx3ncx6brgo4mv6wki5h1ko';

const FRONTPAGE_HOME_SUB = "_";

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

String currentPostId = "";
bool notNull(Object o) => o != null;

String appName = "Lyre";
String appVersion = "0.1";

String youtubeApiKey = "ENTER_YT_API_KEY_HERE";

int perPage = 25;
int currentCount = 0;

bool preCollapsed = false;

List<Submission> recentlyViewed = [];

// * String constants
const clipBoardErrorMessage = "Clipboard is not Available";
const noConnectionErrorMessage = "No Internet Connection.";