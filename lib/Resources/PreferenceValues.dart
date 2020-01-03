import 'package:lyre/Resources/globals.dart';

// * Assets
const ASSET_DEFAULT_SUBSCRIPTIONS = "assets/defaultSubscriptions.txt";
// TODO: Add frontpage banner (Transparent with user-defined background color)
const ASSET_FRONTPAGE_BANNER_DAY = "assets/banner_frontpage.png";
const ASSET_FRONTPAGE_BANNER_NIGHT = "assets/banner_frontpage.png";

// * Settings
const BOX_SETTINGS = "settings";
const BOX_SUBSCRIPTIONS_PREFIX = "subscriptionsbox_";

// * Themes
const CURRENT_THEME = "currentTheme";

// * Subreddits
const HOME = "preferencesHome";
const HOME_DEFAULT = "Frontpage";
const SUBREDDIT_HOME = "startUpSubreddit";
const SUBREDDIT_HOME_DEFAULT = "_";

// * Submissions
const SUBMISSION_VIEWMODE = "submissionViewMode";
const SUBMISSION_VIEWMODE_DEFAULT = PostView.Compact;
const SUBMISSION_PREVIEW_SHOWCIRCLE = "submissionShowCircle";
const SUBMISSION_PREVIEW_SHOWCIRCLE_DEFAULT = false;
const SUBMISSION_DEFAULT_SORT_TYPE = "defaultSortType";
const SUBMISSION_DEFAULT_SORT_TYPE_DEFAULT = "hot";
const SUBMISSION_DEFAULT_SORT_TIME = "defaultSortTime";
const SUBMISSION_DEFAULT_SORT_TIME_DEFAULT = "24h";
const SUBMISSION_RESET_SORTING = "resetSortingWhenRefreshing";
const SUBMISSION_RESET_SORTING_DEFAULT = true;
const SUBMISSION_AUTO_LOAD = "autoLoadPosts";
const SUBMISSION_AUTO_LOAD_DEFAULT = false;

// * Comments
const COMMENTS_DEFAULT_SORT = "defaultCommentsSort";
const COMMENTS_DEFAULT_SORT_DEFAULT = "Confidence";
const COMMENTS_PRECOLLAPSE = "preCollapse";
const COMMENTS_PRECOLLAPSE_DEFAULT = false;

// * Images & Videos
const IMAGE_ENABLE_ROTATION = "enableImageRotation";
const IMAGE_ENABLE_ROTATION_DEFAULT = false;
const VIDEO_ENABLE_ROTATION = "enableVideoRotation";
const VIDEO_ENABLE_ROTATION_DEFAULT = false;
const IMAGE_BLUR_LEVEL = "imageBlurLever";
const IMAGE_BLUR_LEVEL_DEFAULT = 20;
const IMAGE_SHOW_FULLSIZE = "imageShowFullPreviews";
const IMAGE_SHOW_FULLSIZE_DEFAULT = false;
const VIDEO_LOOP = "videoLoop";
const VIDEO_LOOP_DEFAULT = true;
const VIDEO_AUTO_MUTE = "videoAutoMute";
const VIDEO_AUTO_MUTE_DEFAULT = true;
const IMGUR_THUMBNAIL_QUALITY = "imgurAlbumQuality";
const IMGUR_THUMBNAIL_QUALITY_DEFAULT = "Small Square (90x90)";
// Column amount are 'auto' by default
const ALBUM_COLUMN_AMOUNT_PORTRAIT = "albumColumnAmountPortrait";
const ALBUM_COLUMN_AMOUNT_LANDSCAPE = "albumColumnAmountLandscape";

// * Filters:
const SHOW_NSFW_PREVIEWS = "showNSFWPreviews";
const SHOW_NSFW_PREVIEWS_DEFAULT = false;
const SHOW_SPOILER_PREVIEWS = "showSpoilerPreviews";
const SHOW_SPOILER_PREVIEWS_DEFAULT = false;