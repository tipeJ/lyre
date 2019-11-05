import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, List<dynamic>> {
  final List<dynamic> firstState;

  CommentsBloc({this.firstState}) {
    if (firstState != null) addCommentsFromForest(firstState);
  }


  @override
  List<dynamic> get initialState => comments;

  List<CommentM> comments = []; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.
  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

  void collapse(int location){
    var currentIndex = location+1;
    int ogdepth = comments[location].c.data["depth"];
    bool visible = !comments[location+1].visible;
    int lastIndex;
    while (comments[currentIndex].c.data["depth"] != ogdepth) {
      lastIndex = currentIndex;
      currentIndex++;
    }
   for (var i = currentIndex; i < lastIndex; i++) {
     comments[i].visible = visible;
   }
    return;
    while(true){
      if(currentIndex == comments.length - 1) break; //  the end of the list

      var object = comments[currentIndex];

      if (currentIndex !=location && object.c.data['depth'] == comments[location].c.data["depth"]) break; // When this occurs we've reached another comment of the same level

      object.visible = visible;

      currentIndex++;
    }
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
      if(more.children == null && more.children.isEmpty){
          yield comments; //In case of an error, return the same list
      }
      var results = await more.comments(update: true);
      comments.removeAt(event.location); //Removes the used MoreComments object
      comments.insertAll(event.location, results.map((c) => CommentM.from(c)).toList()); //Inserts the received objects into the comment list
    } else if(event is Collapse){
      var currentIndex = event.location+1;
      bool visible = !comments[event.location+1].visible;
      while(true){
        if(currentIndex == comments.length - 1) break; //  the end of the list

        var object = comments[currentIndex];

        if (currentIndex != event.location && object.c.data['depth'] == comments[event.location].c.data["depth"]) break; // When this occurs we've reached another comment of the same level

        object.visible = visible;

        currentIndex++;
      }
      yield comments;
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