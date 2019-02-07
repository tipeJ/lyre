import '../Resources/repository.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/item_model.dart';
import '../Models/Comment.dart';

class CommentsBloc {
  final _repository = Repository();
  final _commentsFetcher = PublishSubject<CommentM>();

  Observable<CommentM> get allComments => _commentsFetcher.stream;
  fetchComments() async {
    CommentM commentM = await _repository.fetchComments();
    _commentsFetcher.sink.add(commentM);
  }

  dispose() {
    _commentsFetcher.close();
  }

}

final bloc = CommentsBloc();