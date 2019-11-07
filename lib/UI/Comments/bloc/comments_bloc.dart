import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, List<dynamic>> {
  final List<dynamic> firstState;
  List<CommentM> btsC = [];

  CommentsBloc({this.firstState}) {
    if (firstState != null && comments.isEmpty) addCommentsFromForest(firstState);
  }

  @override
  List<dynamic> get initialState => comments;

  List<CommentM> comments = []; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.

  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

  void _collapse(int location){
    var currentIndex = location+1;
    if (currentIndex == comments.length) return;
    int ogdepth = comments[location].c.data["depth"];
    bool visible = !comments[location+1].visible;
    int lastIndex;
    while (comments[currentIndex].c.data["depth"] != ogdepth) {
      lastIndex = currentIndex;
      currentIndex++;
    }
    for (var i = location+1; i <= lastIndex; i++) {
      comments[i].visible = visible;      
    }
    return;
  }

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
      if(more.children != null && more.children.isNotEmpty){
        var results = await more.comments(update: true);
        comments.removeAt(event.location); //Removes the used MoreComments object
        comments.insertAll(event.location, results.map((c) => CommentM.from(c)).toList()); //Inserts the received objects into the comment list
      }
      
    } else if(event is Collapse){
      _collapse(event.location);
    }
    loadingMoreId = ""; //Resets the loadingMoreId value.
    yield comments; //Return the updated list of dynamic comment objects.
    }
  //Recursing function that adds the comments to the list from a CommentForest
  void addCommentsFromForest(List<dynamic> forest){
    forest.forEach((f){
      if(f is MoreComments){
        comments.add(CommentM.from(f));
      } else if(f is Comment){
        comments.add(CommentM.from(f));
        if(f.replies != null && f.replies.comments.isNotEmpty){
          addCommentsFromForest(f.replies.toList());
        }
      }
    });
  }
}
class CommentM {
  final dynamic c;
  bool visible;

  CommentM(this.c, this.visible);

  static CommentM from(dynamic object) {

    return CommentM(object, true);
  }
}