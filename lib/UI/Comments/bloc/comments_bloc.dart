import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:lyre/Models/Comment.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, List<dynamic>> {
  @override
  List<dynamic> get initialState => [];

  List<dynamic> comments = []; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.
  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

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
      comments.removeAt(event.location); //Removes the used MoreComments object
      comments.insertAll(event.location, results); //Inserts the received objects into the comment list
      }
      loadingMoreId = ""; //Resets the loadingMoreId value.
      yield comments; //Return the updated list of dynamic comment objects.
    }   
  //Recursing function that adds the comments to the list from a CommentForest
  void addCommentsFromForest(CommentForest forest){
    forest.comments.forEach((f){
      if(f is MoreComments){
        comments.add(f);
      } else if(f is Comment){
        comments.add(f);
        if(f.replies != null && f.replies.comments.isNotEmpty){
          addCommentsFromForest(f.replies);
        }
      }
    });
  }
}
