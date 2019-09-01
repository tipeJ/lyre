import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:meta/meta.dart';
import '../../Resources/globals.dart';

@immutable
class PostsState extends Equatable {
  final List<UserContent> userContent;
  final ContentSource contentSource;

  TypeFilter temporaryType = currentSortType;
  String temporaryTime = currentSortTime;

  List<String> usernamesList;
  RedditUser currentUser;

  String targetRedditor;

  PostsState({
    @required this.contentSource,
    @required this.userContent,
    this.usernamesList,
    this.currentUser,
    this.targetRedditor
  }) : super([userContent, usernamesList, currentUser, targetRedditor]);

  String getSourceString(){
    switch (currentContentSource) {
      case ContentSource.Subreddit:
        return 'r/$currentSubreddit';
      case ContentSource.Redditor:
        return 'u/$targetRedditor';
      default:
        return '';
        break;
    }
  }
  String getFilterString(){
    if(temporaryType == TypeFilter.Top || temporaryType == TypeFilter.Controversial){
      return parseTypeFilter() + " ● " + temporaryTime;
    }else{
      return parseTypeFilter();
    }
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
    }
  }
}

class InitialPostsState extends PostsState {}
