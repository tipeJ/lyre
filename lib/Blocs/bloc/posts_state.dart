import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:meta/meta.dart';
import '../../Resources/globals.dart';

@immutable
class PostsState extends Equatable {

  //CONTENT
  final List<UserContent> userContent;
  final ContentSource contentSource;

  //SORTING
  TypeFilter temporaryType = currentSortType;
  String temporaryTime = currentSortTime;

  //LOGGED IN USER INFORMATION
  List<String> usernamesList;
  RedditUser currentUser;

  //WHEN TARGETING REDDITOR
  String targetRedditor;

  //WHEN TARGETING SELF
  SelfContentType selfContentType;

  //SUBREDDIT STUFF (ONLY WHEN CONTENTSOURCE IS SUBREDDIT)
  WikiPage sideBar;
  Subreddit subreddit;
  List<StyleSheetImage> styleSheetImages;
  String headerImage;

  Box preferences;

  PostsState({
    @required this.contentSource,
    @required this.userContent,
    this.usernamesList,
    this.currentUser,
    this.targetRedditor,
    this.selfContentType,
    this.sideBar,
    this.styleSheetImages,
    this.preferences,
    this.subreddit,
    this.headerImage
  });

  List<dynamic> get props => [userContent, usernamesList, currentUser, targetRedditor, selfContentType, styleSheetImages, headerImage, subreddit];

  String getSourceString(){
    switch (contentSource) {
      case ContentSource.Subreddit:
        return 'r/$currentSubreddit';
      case ContentSource.Redditor:
        return 'u/$targetRedditor';
      case ContentSource.Self:
        return currentUser.username;
      default:
        return '';
    }
  }
  String getFilterString(){
    String filterString = "";

    if(contentSource == ContentSource.Self){
      switch (selfContentType) {
        case SelfContentType.Comments:
          filterString = "Comments";
          break;
        case SelfContentType.Hidden:
          filterString = "Hidden";
          break;
        case SelfContentType.Saved:
          filterString = "Saved";
          break;
        case SelfContentType.Submitted:
          filterString = "Submitted";
          break;
        case SelfContentType.Upvoted:
          filterString = "Upvoted";
          break;
        case SelfContentType.Watching:
          filterString = "Watching";
          break;
        default:
          break;
      }
      filterString += " ● ";
    }

    if(temporaryType == TypeFilter.Top || temporaryType == TypeFilter.Controversial){
      filterString += parseTypeFilter() + " ● " + temporaryTime;
    }else{
      filterString += parseTypeFilter();
    }
    return filterString;
  }
  String parseTypeFilter(){
    switch (temporaryType) {
      case TypeFilter.Hot:
        return 'hot';
      case TypeFilter.New:
        return 'new';
      case TypeFilter.Rising:
        return 'rising';
      case TypeFilter.Top:
        return 'top';
      case TypeFilter.Controversial:
        return 'controversial';
      case TypeFilter.Comments:
        return 'comments';
      case TypeFilter.Gilded:
        return 'gilded';
      case TypeFilter.Best:
        return 'best';
      default:
        return ""; //Shouldn't happen
    }
  }
}