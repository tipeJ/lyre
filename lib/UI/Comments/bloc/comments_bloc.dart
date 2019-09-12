import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:lyre/Models/Comment.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, List<dynamic>> {
  @override
  List<commentResult> get initialState => [];

  List<dynamic> comments = [];
  String loadingMoreId = "";

  @override
  Stream<List<dynamic>> mapEventToState(
    CommentsEvent event
  ) async* {
    if(event is SortChanged){
      comments = []; //Removes previous items from the comment list
      var forest = await event.submission.refreshComments(sort: event.commentSortType);
      addCommentsFromForest(forest);
    } else if(event is FetchMore){
      var more = event.moreComments;
      if(more.children == null && more.children.isEmpty){
        yield comments; //In case of an error, return the same list
      }
      var results = await more.comments(update: true);
      comments.removeAt(event.location);
      var commentsList = List<dynamic>();
      results.forEach((comment){
        commentsList.add(commentC.fromC(comment));
      });
      comments.insertAll(event.location, commentsList);
    }
    yield comments; //Return the updated list of dynamic comment objects.
  }
  //Recursing function that adds the comments to the list from a CommentForest
  void addCommentsFromForest(CommentForest forest){
    forest.comments.forEach((f){
      if(f is MoreComments){
        comments.add(moreC(f.data));
      } else if(f is Comment){
        comments.add(commentC.fromC(f));
        addCommentsFromForest(f.replies);
      }
    });
  }
}
