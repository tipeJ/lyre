import '../Resources/repository.dart';
import '../Resources/globals.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/item_model.dart';
import '../Models/Comment.dart';

class PostsBloc {
  final _repository = Repository();
  final _postsFetcher = PublishSubject<ItemModel>();
  ItemModel latestModel;

  Observable<ItemModel> get allPosts => _postsFetcher.stream;

  fetchAllPosts() async {
    ItemModel itemModel = await _repository.fetchPosts(false);
    latestModel = itemModel;
    _postsFetcher.sink.add(latestModel);
    currentCount = 25;
  }
  fetchMore() async {
    lastPost = latestModel.results.last.id;
    currentCount += perPage;
    print("START FETCH MORE");
    ItemModel itemModel = await _repository.fetchPosts(true);
    print("FETCHED");
    if(latestModel.results == null || latestModel == null){
      print("fuckiong ell");
    }
    latestModel.results.addAll(itemModel.results);
    print("ADDED");
    print(latestModel.results.length);
    _postsFetcher.sink.add(latestModel);
    print("SINK ADDED (END)");
  }

  dispose() {
    _postsFetcher.close();
  }

}

final bloc = PostsBloc();