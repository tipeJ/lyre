import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity/connectivity.dart';
import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'bloc.dart';
import 'package:lyre/Resources/globals.dart';

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsState firstState;

  PostsBloc({this.firstState});

  @override //Default: Empty list of UserContent
  PostsState get initialState => firstState ?? PostsState(state: LoadingState.Inactive, viewMode: PostView.Compact, userContent: const [], contentSource : ContentSource.Subreddit, target: homeSubreddit, typeFilter: TypeFilter.Best, timeFilter: 'all');

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
        target: state.target,
        sideBar: state.sideBar,
        typeFilter: state.typeFilter,
        timeFilter: state.timeFilter,
        viewMode: PostView.Compact
      );
    } else {
      /// When [ContentSource] has been Changed
      if(event is PostsSourceChanged){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: event.source,
          target: event.target,
          userContent: const [],
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: state.viewMode
        );
        WikiPage sideBar;
        Subreddit subreddit;
        List<UserContent> userContent;

        LoadingState loadingState = LoadingState.Inactive;
        String errorMessage;

        final target = event.target ?? state.target;

        final source =  target == FRONTPAGE_HOME_SUB ? ContentSource.Frontpage : event.source ?? state.contentSource;
        final userName = _repository.isLoggedIn() ? (await _repository.getLoggedInUser()).displayName.toLowerCase() : '';
        final preferences = await Hive.openBox(BOX_SETTINGS_PREFIX + userName);
        TypeFilter sortType;
        String sortTime;
        PostView viewMode = state.viewMode;

        if (preferences.get(SUBMISSION_RESET_SORTING, defaultValue: SUBMISSION_RESET_SORTING_DEFAULT)){ 
          // Reset Current Sort Configuration if user has set it to reset
          sortType = parseTypeFilter(preferences.get(SUBMISSION_DEFAULT_SORT_TYPE, defaultValue: sortTypes[0]));
          sortTime = preferences.get(SUBMISSION_DEFAULT_SORT_TIME, defaultValue: defaultSortTime);
        }
        if (preferences.get(SUBMISSION_VIEWMODE_RESET, defaultValue: SUBMISSION_VIEWMODE_RESET_DEFAULT)) {
          viewMode = preferences.get(SUBMISSION_VIEWMODE, defaultValue: SUBMISSION_VIEWMODE_DEFAULT);
        }

        switch (source) {
          case ContentSource.Subreddit:
            userContent = await _repository.fetchUserContent(sortType, target, source: source, timeFilter: sortTime, );
            subreddit = await _repository.getSubreddit(target);
            sideBar = subreddit != null ? await _repository.getWikiPage(WIKI_SIDEBAR_ARGUMENTS, subreddit.displayName) : null;
            break;
          case ContentSource.Redditor:
            userContent = await _repository.fetchUserContent(sortType, target, source: source, timeFilter: sortTime, );
            break;
          case ContentSource.Self:
            userContent = await _repository.fetchSelfUserContent(target, typeFilter: sortType, timeFilter: sortTime);
            break;
          case ContentSource.Frontpage:
            userContent = await _repository.fetchUserContent(sortType, target, source: source, timeFilter: sortTime, );
            break;
          default:
            // TODO: Implement domains
            break;
        }

        if (userContent.isEmpty) {
          loadingState = LoadingState.Error;
          errorMessage = "No Submissions Were Returned";
        }

        yield PostsState(
          state: loadingState,
          errorMessage: errorMessage,
          userContent: userContent, 
          contentSource : source,
          target: target, 
          sideBar: sideBar,
          subreddit: subreddit,
          typeFilter: sortType,
          timeFilter: sortTime,
          viewMode: viewMode
        );
        preferences.close();
      } else if (event is RefreshPosts){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: state.contentSource,
          target: state.target,
          userContent: const [],
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: state.viewMode
        );
        List<UserContent> userContent;
        LoadingState loadingState = LoadingState.Inactive;
        String errorMessage;
        if (state.contentSource != ContentSource.Self) {
          userContent = await _repository.fetchUserContent(state.typeFilter, state.target, source: state.contentSource, timeFilter: state.timeFilter);
        } else {
          userContent = await _repository.fetchSelfUserContent(state.target, typeFilter: state.typeFilter, timeFilter: state.timeFilter);
        }
        if (userContent.isEmpty) {
          loadingState = LoadingState.Error;
          errorMessage = "No Submissions Were Returned";
        }
        yield PostsState(
          state: loadingState,
          errorMessage: errorMessage,
          userContent: userContent,
          contentSource: state.contentSource,
          target: state.target,
          sideBar: state.sideBar,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: state.viewMode
        );
      } else if (event is ParamsChanged){
        yield PostsState(
          state: LoadingState.Refreshing,
          contentSource: state.contentSource,
          target: state.target,
          userContent: const [],
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: state.viewMode
        );
        List<UserContent> userContent;
        LoadingState loadingState = LoadingState.Inactive;
        String errorMessage;
        if (state.contentSource != ContentSource.Self) {
          userContent = await _repository.fetchUserContent(event.typeFilter, state.target, source: state.contentSource, timeFilter: event.timeFilter, );
        } else {
          userContent = await _repository.fetchSelfUserContent(state.target, typeFilter: event.typeFilter, timeFilter: event.timeFilter);
        }
        if (userContent.isEmpty) {
          loadingState = LoadingState.Error;
          errorMessage = "No Submissions Were Returned";
        }
        yield PostsState(
          state: loadingState,
          errorMessage: errorMessage,
          userContent: userContent,
          contentSource: state.contentSource,
          target: state.target,
          sideBar: state.sideBar,
          typeFilter: event.typeFilter,
          timeFilter: event.timeFilter,
          viewMode: state.viewMode
        );
      } else if (event is FetchMore){
        yield PostsState(
          state: LoadingState.LoadingMore,
          contentSource: state.contentSource,
          target: state.target,
          userContent: state.userContent,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: state.viewMode
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
          target: state.target,
          sideBar: state.sideBar,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: state.viewMode
        );
      } else if (event is ViewModeChanged) {
        yield PostsState(
          state: state.state,
          errorMessage: state.errorMessage,
          userContent: state.userContent,
          contentSource: state.contentSource,
          target: state.target,
          subreddit: state.subreddit,
          sideBar: state.sideBar,
          typeFilter: state.typeFilter,
          timeFilter: state.timeFilter,
          viewMode: event.viewMode
        );
      }
    }
  }
}