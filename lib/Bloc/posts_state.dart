import 'package:basic_utils/basic_utils.dart';
import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:meta/meta.dart';
import 'package:lyre/Resources/globals.dart';

@immutable
class PostsState extends Equatable {
  final LoadingState state;
  final String errorMessage;

  //CONTENT
  final List<UserContent> userContent;
  final ContentSource contentSource;
  final dynamic target;

  //SORTING
  final TypeFilter typeFilter;
  final String timeFilter;

  //SUBREDDIT STUFF (ONLY WHEN CONTENTSOURCE IS SUBREDDIT)
  final WikiPage sideBar;
  final Subreddit subreddit;

  ///Media Preview Type
  final PostView viewMode;

  PostsState({
    @required this.state,
    @required this.contentSource,
    @required this.target,
    @required this.userContent,
    @required this.typeFilter,
    @required this.timeFilter,
    @required this.viewMode,
    this.errorMessage,
    this.sideBar,
    this.subreddit,
  });

  List<dynamic> get props => [state, userContent, target, errorMessage, viewMode];

  String getSourceString({bool prefix = true}){
    switch (contentSource) {
      case ContentSource.Subreddit:
        return '${prefix ? "r/" : ""}$target';
      case ContentSource.Redditor:
        return '${prefix ? "u/" : ""}$target';
      case ContentSource.Self:
        return target.toString().split('.').last;
      default:
        return 'frontpage';
    }
  }
  String getFilterString(){
    String filterString = "";

    if(contentSource == ContentSource.Self){
      filterString = target.toString().split('.').last;
      filterString += " ● ";
    }

    if(typeFilter == TypeFilter.Top || typeFilter == TypeFilter.Controversial){
      filterString += StringUtils.capitalize(_parseTypeFilter()) + " | " + StringUtils.capitalize(timeFilter);
    }else{
      filterString += StringUtils.capitalize(_parseTypeFilter());
    }
    return filterString;
  }

  String _parseTypeFilter(){
    switch (typeFilter) {
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