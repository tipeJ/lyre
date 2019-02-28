library lyre.globals;

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
String currentPostId = "";

String appName = "Lyre";
String appVersion = "0.1";

int perPage = 25;
int currentCount = 0;
String lastPost = "";

bool autoLoad = false;