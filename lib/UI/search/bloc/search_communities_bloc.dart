import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/UI/search/bloc/search_communities_state.dart';
import 'package:lyre/UI/search/bloc/search_communities_event.dart';

class SearchCommunitiesBloc extends Bloc<SearchCommunitiesEvent, SearchCommunitiesState> {
  @override
  SearchCommunitiesState get initialState => SearchCommunitiesState(loading: false, users: []);

  @override
  Stream<SearchCommunitiesState> mapEventToState(
    SearchCommunitiesEvent event,
  ) async* {
    if (event is UserSearchQueryChanged) {
      yield(SearchCommunitiesState(loading: true, users: []));
      var x = await PostsProvider().searchCommunities(event.query);
      yield SearchCommunitiesState(users: x, loading: false);
    }
  }
}
