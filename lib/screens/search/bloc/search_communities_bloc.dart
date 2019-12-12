import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/screens/search/bloc/search_communities_state.dart';
import 'package:lyre/screens/search/bloc/search_communities_event.dart';

class SearchCommunitiesBloc extends Bloc<SearchCommunitiesEvent, SearchCommunitiesState> {
  @override
  SearchCommunitiesState get initialState => SearchCommunitiesState(loading: false, communities: [], query: '');


  @override
  Stream<SearchCommunitiesState> mapEventToState(
    SearchCommunitiesEvent event,
  ) async* {
    if (event is UserSearchQueryChanged) {
      yield(SearchCommunitiesState(loading: true, communities: [], query: event.query));
      var x = await PostsProvider().searchCommunities(event.query);
      yield SearchCommunitiesState(communities: x, loading: false, query: event.query);
    } else if (event is LoadMoreCommunities) {
      yield (SearchCommunitiesState(loading: true, communities: state.communities, query: state.query));
      var x = await PostsProvider().searchCommunities(state.query, loadMore: true, lastId: state.communities.last.fullname);
      final communities = state.communities..addAll(x);
      yield (SearchCommunitiesState(loading: false, communities: communities, query: state.query));
    }
  }
}
