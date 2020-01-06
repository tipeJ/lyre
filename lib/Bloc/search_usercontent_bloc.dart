import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import './bloc.dart';

class SearchUsercontentBloc extends Bloc<SearchUsercontentEvent, SearchUsercontentState> {
  @override
  SearchUsercontentState get initialState => SearchUsercontentState(loading: false, results: [], parameters: CommentSearchParameters(query: ''));

  @override
  Stream<SearchUsercontentState> mapEventToState(
    SearchUsercontentEvent event,
  ) async* {
    if (event is UserContentQueryChanged) {
      yield(SearchUsercontentState(loading: true, results: [], parameters: event.parameters));
      final results = await PostsProvider().searchPushShiftComments(event.parameters);
      yield(SearchUsercontentState(loading: false, results: results, parameters: event.parameters));
    }
  }
}
