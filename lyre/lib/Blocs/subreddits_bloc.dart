import '../Resources/repository.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/Subreddit.dart';

class SubsBloc {
  final _repository = Repository();
  final _subsFetcher = PublishSubject<SubredditM>();

  Observable<SubredditM> get getSubs => _subsFetcher.stream;

  fetchSubs(String query) async {
    SubredditM subM = await _repository.fetchSubs(query);
    _subsFetcher.sink.add(subM);
  }

  dispose() {
    _subsFetcher.close();
  }

}

final sub_bloc = SubsBloc();