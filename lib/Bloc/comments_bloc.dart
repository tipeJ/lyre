import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'bloc.dart';
import 'package:lyre/Resources/globals.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  CommentsState _firstState;

  CommentsBloc(UserContent initialContent){
    _firstState = CommentsState(state: LoadingState.Inactive, submission: initialContent, comments: const [], sortType: CommentSortType.blank);
  }

  @override
  CommentsState get initialState => _firstState ?? CommentsState(state: LoadingState.Inactive, submission: null, comments: const [], sortType: CommentSortType.blank);

  List<CommentM> get _comments => state.comments; //Even though this type is dynamic, it will only contain Comment or MoreComment objects.

  String loadingMoreId = ""; //The ID of the currently loading MoreComments object

  void _collapse(int location){
    var currentIndex = location+1;
    int parentDepth = _comments[location].c.data["depth"];
    if (currentIndex == _comments.length || _comments[currentIndex].c.data['depth'] == parentDepth) return;
    bool visible = !_comments[location+1].visible;
    int lastIndex;
    while (currentIndex != _comments.length && _comments[currentIndex].c.data["depth"] != parentDepth) {
      lastIndex = currentIndex;
      currentIndex++;
    }
    for (var i = location+1; i <= lastIndex; i++) {
      _comments[i].visible = visible;      
    }
  }

  @override
  Stream<CommentsState> mapEventToState(
    CommentsEvent event
  ) async* {
    if(event is SortChanged){
      yield CommentsState(state: LoadingState.Refreshing, submission: state.submission ?? _firstState.submission, comments: const [], sortType: event.commentSortType, parentComment: state.parentComment, showSubmission: state.showSubmission); //Return the updated list of dynamic comment objects.      
      Comment parentComment;
      Submission submission;
      final userContent = event.submission;
      List<CommentM> comments;
      //Only should occur when the submission is fetched from a comment permalink for the first time.
      if (userContent is CommentRef || userContent is Comment) {
        final Comment comment = userContent is CommentRef ? await userContent.populate() : userContent;
        parentComment = comment.isRoot ? comment : await comment.parent();
        final submissionRef = parentComment.submission;
        submission = await submissionRef.populate();
        comments = _retrieveCommentsFromForest([parentComment]);
      } else if (state.parentComment != null && userContent is Submission) {
        submission = userContent;
        comments = _retrieveCommentsFromForest(userContent.comments.comments);
      } else {
        submission = event.submission != null ? event.submission as Submission : state.submission;
        var forest = await submission.refreshComments(sort: event.commentSortType);
        comments = _retrieveCommentsFromForest(forest.comments);
      }
      yield CommentsState(state: LoadingState.Inactive, submission: submission, comments: comments, sortType: event.commentSortType, parentComment: parentComment, showSubmission: state.showSubmission); //Return the updated list of dynamic comment objects.      
    } else if (event is RefreshComments){
      yield CommentsState(state: LoadingState.Refreshing, submission: state.submission, comments: state.comments, sortType: state.sortType, parentComment: state.parentComment, showSubmission: state.showSubmission); //Return the updated list of dynamic comment objects.      
      Comment parentComment;
      Submission submission;
      final userContent = state.submission;
      List<CommentM> comments;
      //Only should occur when the submission is fetched from a comment permalink for the first time.
      if (userContent is CommentRef || userContent is Comment) {
        final Comment comment = userContent is CommentRef ? await userContent.populate() : userContent;
        parentComment = comment.isRoot ? comment : await comment.parent();
        comments = _retrieveCommentsFromForest([parentComment]);
      } else if (state.parentComment != null && userContent is Submission) {
        submission = userContent;
        comments = _retrieveCommentsFromForest(userContent.comments.comments);
      } else {
        submission = userContent;
        var forest = await submission.refreshComments(sort: state.sortType);
        comments = _retrieveCommentsFromForest(forest.comments);
      }
      yield CommentsState(state: LoadingState.Inactive, submission: submission, comments: comments, sortType: state.sortType, parentComment: parentComment, showSubmission: state.showSubmission); //Return the updated list of dynamic comment objects.        
    } else if (event is FetchMoreComments){
      yield CommentsState(state: LoadingState.LoadingMore, submission: state.submission, comments: _comments, sortType: state.sortType, parentComment: state.parentComment, showSubmission: state.showSubmission); //Return the updated list of dynamic comment objects.      
      var more = event.moreComments;
      var currentList = _comments;
      if(more.children != null && more.children.isNotEmpty){
        var results = await more.comments(update: true);
        var currentList = state.comments;
        currentList.removeAt(event.location); //Removes the used MoreComments object
        currentList.insertAll(event.location, _retrieveCommentsFromForest(results)); //Inserts the received objects into the comment list
      }
      yield CommentsState(state: LoadingState.Inactive, submission: state.submission, comments: currentList, sortType: state.sortType, showSubmission: state.showSubmission); //Return the updated list of dynamic comment objects.      
    } else if (event is Collapse){
      _collapse(event.location);
      yield CommentsState(state: state.state, submission: state.submission, comments: _comments, sortType: state.sortType, showSubmission: state.showSubmission);
    } else if (event is AddComment){
      final c = event.comment;
      c.data['depth'] = state.comments[event.location].c.data['depth'] + 1;
      state.comments.insert(event.location+1, CommentM.from(c));
      yield CommentsState(state: state.state, submission: state.submission, comments: state.comments, sortType: state.sortType, showSubmission: state.showSubmission);
    } else if (event is ToggleSubmissionView) {
      yield CommentsState(state: state.state, submission: state.submission, comments: state.comments, sortType: state.sortType, showSubmission: !state.showSubmission);
    }
    loadingMoreId = ""; //Resets the loadingMoreId value.
    }
  
  /// Recursing function that adds the _comments to the list from a CommentForest and returns the list
  List<CommentM> _retrieveCommentsFromForest(List<dynamic> forest) {
    final List<CommentM> list = [];
    forest.forEach((f){
      if(f is MoreComments){
        list.add(CommentM.from(f));
      } else if(f is Comment){
        list.add(CommentM.from(f));
        if(f.replies != null && f.replies.comments.isNotEmpty){
          list.addAll(_retrieveCommentsFromForest(f.replies.comments));
        }
      }
    });
    return list;
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