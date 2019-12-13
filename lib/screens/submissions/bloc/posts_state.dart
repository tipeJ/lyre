import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/screens/submissions/bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:lyre/Resources/globals.dart';

@immutable
class PostsState extends Equatable {
  LoadingState state;

  //CONTENT
  final List<UserContent> userContent;
  final ContentSource contentSource;
  final dynamic target;

  //SORTING
  TypeFilter temporaryType = currentSortType;
  String temporaryTime = currentSortTime;

  //LOGGED IN USER INFORMATION
  RedditUser currentUser;

  //SUBREDDIT STUFF (ONLY WHEN CONTENTSOURCE IS SUBREDDIT)
  WikiPage sideBar;
  Subreddit subreddit;


  PostsState({
    @required this.state,
    @required this.contentSource,
    @required this.target,
    @required this.userContent,
    this.currentUser,
    this.sideBar,
    this.subreddit,
  });

  List<dynamic> get props => [state, userContent, target];

  String getSourceString({@required bool prefix}){
    switch (contentSource) {
      case ContentSource.Subreddit:
        return '${prefix ? "r/" : ""}$target';
      case ContentSource.Redditor:
        return '${prefix ? "u/" : ""}$target';
      case ContentSource.Self:
        return currentUser.username;
      default:
        return '';
    }
  }
  String getFilterString(){
    String filterString = "";

    if(contentSource == ContentSource.Self){
      switch (target) {
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
      filterString += parseTypeFilter() + " | " + temporaryTime;
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