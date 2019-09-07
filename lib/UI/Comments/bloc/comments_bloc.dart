import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  @override
  CommentsState get initialState => InitialCommentsState();

  @override
  Stream<CommentsState> mapEventToState(
    CommentsEvent event,
  ) async* {
    // TODO: Add Logic
  }
}
