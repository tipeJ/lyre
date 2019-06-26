library lyre.globals;
import '../Models/Post.dart';

String BASE_URL = "https://www.reddit.com";
String COMMENTS_BASE_URL = "https://www.reddit.com/comments/";
String SUBREDDITS_BASE_URL = "https://www.reddit.com/subreddits/";

String GFYCAT_GET_URL = "https://api.gfycat.com/v1/gfycats/";
String GFYCAT_CLIENT_ID = "2__lD9Ci";
String GFYCAT_CLIENT_SECRET = "waadJXMtWmfHC45OeMvE9lDrKkhQ9XCR0xLMbaFTuINQPjd4s0mcrnnBN8cMmuAr";

String currentSubreddit = "gifs";
List<String> subreddits = [
  '/r/AskReddit',
  '/r/Science',
  '/r/Android',
  '/r/Technology',
  '/r/WorldNews',
  '/r/Programming',
  '/r/DartLang',
  '/r/India',
  '/r/Europe',
  '/r/News',
  '/r/Futurology',
  '/r/IAmA',
  '/r/TodayILearned',
  '/r/Politics',
  '/r/Gaming',
  '/r/ShowerThoughts',
  '/r/Movies',

];

List<String> sortTypes = [
  "hot",
  "new",
  "rising",
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

String defaultSortType = "hot";
String defaultSortTime = sortTimes[1];

String currentSortType = defaultSortType;
String currentSortTime = "";

String currentPostId = "";

String appName = "Lyre";
String appVersion = "0.1";

String youtubeApiKey = "ENTER_YT_API_KEY_HERE";

int perPage = 25;
int currentCount = 0;
String lastPost = "";

bool autoLoad = false;
bool loopVideos = true;
bool preCollapsed = false;

Post cPost;