import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, List<dynamic>> {
  final List<dynamic> firstState;

  CommentsBloc({this.firstState}) {
    if (firstState != null && _comments.isEmpty) addCommentsFromForest(firstState);
  }

  @override
  List<dynamic> get initialState => _comments;

  List<CommentM> _comments = []; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.

  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

  void _collapse(int location){
    var currentIndex = location+1;
    if (currentIndex == _comments.length) return;
    int ogdepth = _comments[location].c.data["depth"];
    bool visible = !_comments[location+1].visible;
    int lastIndex;
    while (_comments[currentIndex].c.data["depth"] != ogdepth) {
      lastIndex = currentIndex;
      currentIndex++;
    }
    for (var i = location+1; i <= lastIndex; i++) {
      _comments[i].visible = visible;      
    }
    return;
  }

  @override
  Stream<List<dynamic>> mapEventToState(
    CommentsEvent event
  ) async* {
    if(event is SortChanged){
        _comments = []; //Removes previous items from the comment list
        var forest = await event.submission.refreshComments(sort: event.commentSortType);
        addCommentsFromForest(forest.toList());
    } else if(event is FetchMore){
      var more = event.moreComments;
      if(more.children != null && more.children.isNotEmpty){
        var results = await more.comments(update: true);
        _comments.removeAt(event.location); //Removes the used MoreComments object
        _comments.insertAll(event.location, results.map((c) => CommentM.from(c)).toList()); //Inserts the received objects into the comment list
      }
      
    } else if(event is Collapse){
      _collapse(event.location);
    }
    loadingMoreId = ""; //Resets the loadingMoreId value.
    yield _comments; //Return the updated list of dynamic comment objects.
    }
  //Recursing function that adds the _comments to the list from a CommentForest
  void addCommentsFromForest(List<dynamic> forest){
    forest.forEach((f){
      if(f is MoreComments){
        _comments.add(CommentM.from(f));
      } else if(f is Comment){
        _comments.add(CommentM.from(f));
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