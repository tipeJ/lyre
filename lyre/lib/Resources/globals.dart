library lyre.globals;
import '../Models/Post.dart';

String BASE_URL = "https://www.reddit.com";
String COMMENTS_BASE_URL = "https://www.reddit.com/comments/";
String SUBREDDITS_BASE_URL = "https://www.reddit.com/subreddits/";
String currentSubreddit = "/r/all";
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
  "top",
  "controversial",
  "new",
  "rising"
];
List<String> sortTimes = [
  "24h",
  "week",
  "month",
  "year",
  "time"
];

String defaultSortType = "hot";
String defaultSortTime = sortTimes[0];

String currentSortType = defaultSortType;
String currentSortTime = defaultSortTime;

String currentPostId = "";

String appName = "Lyre";
String appVersion = "0.1";

String youtubeApiKey = "ENTER_YT_API_KEY_HERE";

int perPage = 25;
int currentCount = 0;
String lastPost = "";

bool autoLoad = false;
bool preCollapsed = false;

Post cPost;