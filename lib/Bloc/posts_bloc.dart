import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Models/User.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'bloc.dart';
import 'package:lyre/Resources/globals.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsState firstState;

  PostsBloc({this.firstState});

  @override //Default: Empty list of UserContent
  PostsState get initialState => firstState ?? PostsState(state: LoadingState.Inactive, userContent: const [], contentSource : ContentSource.Subreddit, target: homeSubreddit, typeFilter: TypeFilter.Best, timeFilter: 'all');

  final _repository = PostsProvider();

  @override
  Stream<PostsState> mapEventToState(
    PostsEvent event,
  ) async* {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Return state userContent if only fetchMore request has internet error (As we don't want to hide already downloaded submissions)
      List<UserContent> userContent = event is FetchMore ? state.userContent : const [];
      yield PostsState(
        state: LoadingState.Error,
        errorMessage: noConnectionErrorMessage,
        userContent: userContent,
        contentSource: state.contentSource,
        currentUser: state.currentUser,
        target: state.target,
        sideBar: state.sideBar,
        typeFilter: state.typeFilter,
        timeFilter: state.timeFilter,
      );
    } else {
      /// When [ContentSource] has been Changed
      print(event.runtimeType.toString());
      if(event is PostsSourceChanged){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: event.source,
          target: event.target,
          userContent: const [],
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter
        );
        WikiPage sideBar;
        Subreddit subreddit;
        RedditUser currentUser = await PostsProvider().getLatestUser();
        List<UserContent> userContent;

        final source = event.source ?? state.contentSource;
        final preferences = await Hive.openBox(BOX_SETTINGS);
        TypeFilter sortType;
        String sortTime;
        if(preferences.get(SUBMISSION_RESET_SORTING) ?? true){ 
          //Reset Current Sort Configuration if user has set it to reset
          sortType = parseTypeFilter(preferences.get(SUBMISSION_DEFAULT_SORT_TYPE, defaultValue: sortTypes[0]));
          sortTime = preferences.get(SUBMISSION_DEFAULT_SORT_TIME, defaultValue: defaultSortTime);
        }
        final target = event.target ?? state.target;

        switch (source) {
          case ContentSource.Subreddit:
            userContent = await PostsProvider().fetchUserContent(sortType, target, source: source, timeFilter: sortTime, );
            subreddit = await _repository.getSubreddit(target);
            sideBar = subreddit != null ? await _repository.getWikiPage(WIKI_SIDEBAR_ARGUMENTS, subreddit) : null;
            break;
          case ContentSource.Redditor:
            userContent = await PostsProvider().fetchUserContent(sortType, target, source: source, timeFilter: sortTime, );
            break;
          case ContentSource.Self:
            userContent = await _repository.fetchSelfUserContent(target, typeFilter: sortType, timeFilter: sortTime);
            break;
          case ContentSource.Frontpage:
            userContent = await PostsProvider().fetchUserContent(sortType, target, source: source, timeFilter: sortTime, );
            break;
        }

        yield PostsState(
          state: LoadingState.Inactive,
          userContent: userContent, 
          contentSource : source,
          currentUser: currentUser, 
          target: target is String ? target.toLowerCase() : target, 
          sideBar: sideBar,
          subreddit: subreddit,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter
        );
        preferences.close();
      } else if (event is ParamsChanged){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: state.contentSource,
          target: state.target,
          userContent: const [],
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter
        );
        List<UserContent> userContent;
        if (state.contentSource != ContentSource.Self) {
          userContent = await _repository.fetchUserContent(event.typeFilter, state.target, source: state.contentSource, timeFilter: event.timeFilter, );
        } else {
          userContent = await _repository.fetchSelfUserContent(state.target, typeFilter: event.typeFilter, timeFilter: event.timeFilter);
        }
        yield PostsState(
          state: LoadingState.Inactive,
          userContent: userContent,
          contentSource: state.contentSource,
          currentUser: state.currentUser,
          target: state.target,
          sideBar: state.sideBar,
          typeFilter: event.typeFilter,
          timeFilter: event.timeFilter
        );
      } else if (event is FetchMore){
        yield PostsState(
          state: LoadingState.LoadingMore,
          contentSource: state.contentSource,
          target: state.target,
          userContent: state.userContent,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter
        );

        final last = state.userContent.last;
        final after = last is Submission ? last.fullname : (last as Comment).fullname;
        
        List<UserContent> fetchedContent;
        
        if (state.contentSource != ContentSource.Self) {
          fetchedContent = await _repository.fetchUserContent(state.typeFilter, state.target, source: state.contentSource, timeFilter: state.timeFilter, after: after);
        } else {
          fetchedContent = await _repository.fetchSelfUserContent(state.target, typeFilter: state.typeFilter, timeFilter: state.timeFilter, after: after);
        }
        yield PostsState(
          state: LoadingState.Inactive,
          userContent: state.userContent..addAll(fetchedContent),
          contentSource: state.contentSource,
          currentUser: state.currentUser,
          target: state.target,
          sideBar: state.sideBar,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter
        );
      }
    }
  }
}
enum LoadingState {
  Inactive,
  Error,
  LoadingMore,
  Refreshing,
}
