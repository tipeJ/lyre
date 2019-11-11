import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsState _firstState;

  CommentsBloc(UserContent initialContent, [List<dynamic> testList]){
    if (testList != null && testList.isNotEmpty){
      _addCommentsFromForest(testList);
    }
    _firstState = CommentsState(submission: initialContent, comments: _comments, sortType: CommentSortType.blank);
    print(initialState.submission.runtimeType.toString() + "type");
  }

  @override
  CommentsState get initialState => _firstState ?? CommentsState(submission: null, comments: _comments, sortType: CommentSortType.blank);

  List<CommentM> _comments = []; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.

  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

  void _collapse(int location){
    _comments = state.comments;
    var currentIndex = location+1;
    if (currentIndex == _comments.length) return;
    int ogdepth = _comments[location].c.data["depth"];
    bool visible = !_comments[location+1].visible;
    int lastIndex;
    while (currentIndex != _comments.length && _comments[currentIndex].c.data["depth"] != ogdepth) {
      lastIndex = currentIndex;
      currentIndex++;
    }
    for (var i = location+1; i <= lastIndex; i++) {
      _comments[i].visible = visible;      
    }
  }
  bool _loading = false;

  @override
  Stream<CommentsState> mapEventToState(
    CommentsEvent event
  ) async* {
    if(_loading) return; //Prevents duplicate calls.
    _loading = true;
    if(event is SortChanged){
      _comments = [];
      Comment parentComment;
      Submission submission;
      final userContent = event.submission;
      //Only should occur when the submission is fetched from a comment permalink for the first time.
      if (userContent is CommentRef) {
        print('ccc');
        parentComment = await userContent.populate();
        print(parentComment.id + 'parentid');
        final submissionRef = parentComment.submission;
        submission = await submissionRef.populate();
        _addCommentsFromForest([parentComment]);
      } else if (state.parentComment != null && userContent is Submission) {
        submission = userContent;
        _addCommentsFromForest(userContent.comments.comments);
      } else {
        print('fff');
        submission = event.submission as Submission;
        var forest = await submission.refreshComments(sort: event.commentSortType);
        _addCommentsFromForest(forest.comments);
      }
      print(_comments.length.toString() + 'length');
      yield CommentsState(submission: submission, comments: _comments, sortType: event.commentSortType, parentComment: parentComment); //Return the updated list of dynamic comment objects.      
    } else if(event is FetchMore){
      var more = event.moreComments;
      if(more.children != null && more.children.isNotEmpty){
        var results = await more.comments(update: true);
        _addCommentsFromForest(results);
        final currentList = state.comments;
        currentList.removeAt(event.location); //Removes the used MoreComments object
        currentList.insertAll(event.location, _comments); //Inserts the received objects into the comment list
        _comments = currentList;
      }
      yield CommentsState(submission: state.submission, comments: _comments, sortType: state.sortType); //Return the updated list of dynamic comment objects.      
    } else if(event is Collapse){
      _collapse(event.location);
      yield CommentsState(submission: state.submission, comments: _comments, sortType: state.sortType);
    } else if(event is AddComment){
      state.comments.insert(event.location+1, CommentM.from(event.comment));
      yield CommentsState(submission: state.submission, comments: state.comments, sortType: state.sortType);
    }
    loadingMoreId = ""; //Resets the loadingMoreId value.
    _comments = [];
    _loading = false;
    }
  //Recursing function that adds the _comments to the list from a CommentForest
  void _addCommentsFromForest(List<dynamic> forest){
    forest.forEach((f){
      if(f is MoreComments){
        _comments.add(CommentM.from(f));
      } else if(f is Comment){
        _comments.add(CommentM.from(f));
        if(f.replies != null && f.replies.comments.isNotEmpty){
          _addCommentsFromForest(f.replies.comments);
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