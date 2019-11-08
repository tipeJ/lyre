import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  final CommentsState firstState;

  CommentsBloc({this.firstState});

  @override
  CommentsState get initialState => firstState ?? CommentsState(comments: [], sortType: CommentSortType.blank);

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
  Stream<CommentsState> mapEventToState(
    CommentsEvent event
  ) async* {
    if(event is SortChanged){
        var forest = await event.submission.refreshComments(sort: event.commentSortType);
        _comments = forest.toList().map<CommentM>((c) => CommentM.from(c)).toList();
      yield CommentsState(comments: _comments, sortType: event.commentSortType); //Return the updated list of dynamic comment objects.      
    } else if(event is FetchMore){
      var more = event.moreComments;
      if(more.children != null && more.children.isNotEmpty){
        var results = await more.comments(update: true);
        _comments.removeAt(event.location); //Removes the used MoreComments object
        _comments.insertAll(event.location, results.map((c) => CommentM.from(c)).toList()); //Inserts the received objects into the comment list
      }
      yield CommentsState(comments: _comments, sortType: state.sortType); //Return the updated list of dynamic comment objects.      
    } else if(event is Collapse){
      _collapse(event.location);
      yield state;
    }
    loadingMoreId = ""; //Resets the loadingMoreId value.
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