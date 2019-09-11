import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:draw/draw.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  @override
  CommentsState get initialState => CommentsState(forest: null, submission: null);

  @override
  Stream<CommentsState> mapEventToState(
    CommentsEvent event
  ) async* {
    if(event is SourceChanged){
      var commentForest = event.submission.comments;
      yield new CommentsState(forest: commentForest, submission: event.submission);
    } else if(event is FetchMore){
      final forest = currentState.forest;
    }
  }
}
