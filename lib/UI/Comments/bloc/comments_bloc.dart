import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:lyre/Models/Comment.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, List<dynamic>> {
  final List<dynamic> firstState;

  CommentsBloc({this.firstState}) {
    if (firstState != null) addCommentsFromForest(firstState);
    visibles = comments.map((el) => true).toList();
  }
  List<bool> visibles = List();

  List<bool> get() => visibles;

  @override
  List<dynamic> get initialState => comments;

  List<dynamic> comments = []; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.
  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

  @override
  Stream<List<dynamic>> mapEventToState(
    CommentsEvent event
  ) async* {
    if(event is SortChanged){
        comments = []; //Removes previous items from the comment list
        var forest = await event.submission.refreshComments(sort: event.commentSortType);
        addCommentsFromForest(forest.toList());
    } else if(event is FetchMore){
      var more = event.moreComments;
      if(more.children == null && more.children.isEmpty){
          yield comments; //In case of an error, return the same list
      }
      var results = await more.comments(update: true);
      comments.removeAt(event.location); //Removes the used MoreComments object
      comments.insertAll(event.location, results); //Inserts the received objects into the comment list
    } else if(event is Collapse){
      var currentIndex = event.location;
      while(true){
        currentIndex++;
        var c = comments[currentIndex];

        if(currentIndex == comments.length - 1 || c.data['depth'] == event.depth) break; //When this occurs we've reached another comment of the same level or the end of the list

        if(c is Comment){
          c.collapse();
        }
      }
    }else if(event is CollapseX){
      event.c.collapse();
    }
    loadingMoreId = ""; //Resets the loadingMoreId value.
    yield comments; //Return the updated list of dynamic comment objects.
    }
  //Recursing function that adds the comments to the list from a CommentForest
  void addCommentsFromForest(List<dynamic> forest){
    forest.forEach((f){
      if(f is MoreComments){
        comments.add(f);
      } else if(f is Comment){
        comments.add(f);
        if(f.replies != null && f.replies.comments.isNotEmpty){
          addCommentsFromForest(f.replies.toList());
        }
      }
    });
  }
}
