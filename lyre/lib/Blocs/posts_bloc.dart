import '../Resources/repository.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/item_model.dart';
import '../Models/Comment.dart';

class PostsBloc {
  final _repository = Repository();
  final _postsFetcher = PublishSubject<ItemModel>();

  Observable<ItemModel> get allPosts => _postsFetcher.stream;

  fetchAllPosts() async {
    ItemModel itemModel = await _repository.fetchPosts();
    _postsFetcher.sink.add(itemModel);
  }

  dispose() {
    _postsFetcher.close();
  }

}

final bloc = PostsBloc();