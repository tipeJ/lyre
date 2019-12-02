import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/search/bloc/search_users_state.dart';
import './bloc.dart';

class SearchUsersBloc extends Bloc<SearchUsersEvent, SearchUsersState> {
  @override
  SearchUsersState get initialState => SearchUsersState(loading: false, users: []);

  @override
  Stream<SearchUsersState> mapEventToState(
    SearchUsersEvent event,
  ) async* {
    if (event is UserSearchQueryChanged) {
      yield(SearchUsersState(loading: true, users: []));
      var x = await PostsProvider().searchUsers(event.query);
      yield SearchUsersState(users: x, loading: false);
    }
  }
}
