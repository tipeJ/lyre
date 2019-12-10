import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class SearchUsercontentBloc extends Bloc<SearchUsercontentEvent, SearchUsercontentState> {
  @override
  SearchUsercontentState get initialState => InitialSearchUsercontentState();

  @override
  Stream<SearchUsercontentState> mapEventToState(
    SearchUsercontentEvent event,
  ) async* {
    // TODO: Add Logic
  }
}
