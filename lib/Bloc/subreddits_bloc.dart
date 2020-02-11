import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/Subreddit.dart';

class SubsBloc {
  final _repository = PostsProvider();
  final _subsFetcher = PublishSubject<SubredditM>();

  Stream<SubredditM> get getSubs => _subsFetcher.stream;

  fetchSubs(String query) async {
    SubredditM subM = await _repository.fetchSubReddits(query);
    _subsFetcher.sink.add(subM);
  }

  dispose() {
    _subsFetcher.close();
  }

}

final sub_bloc = SubsBloc();