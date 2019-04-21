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
    if(latestModel.results == null || latestModel == null){
      print("FETCH MORE ERROR: RESULTS WERE NULL");
    }
    latestModel.results.addAll(itemModel.results);
    _postsFetcher.sink.add(latestModel);
  }

  dispose() {
    _postsFetcher.close();
  }

  void resetFilters(){
    
  }

  void changeParams(String newType, String newTime){

  }

  String temp_type = "";
  //True for types (controversia, hot, etc.), False for periods (last 24 hours, all time, etc..)
  bool isParamsType = false;

}

final bloc = PostsBloc();