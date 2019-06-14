import '../Resources/repository.dart';
import '../Resources/globals.dart';
import '../Resources/credential_loader.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/item_model.dart';

class PostsBloc {
  final _repository = Repository();
  final _postsFetcher = PublishSubject<ItemModel>();
  ItemModel latestModel;

  Observable<ItemModel> get allPosts => _postsFetcher.stream;
  List<String> usernamesList = new List();

  fetchAllPosts() async {
    temporaryType = currentSortType;
    temporaryTime = currentSortTime;
    ItemModel itemModel = await _repository.fetchPosts(false);
    print("ITEMMODEL LENGTH: " + itemModel.results.length.toString());
    latestModel = itemModel;
    _postsFetcher.sink.add(latestModel);
    currentCount = 25;

    //Currently refreshes list of registered usernames via refreshing list of posts.
    var x = await readUsernames();
    usernamesList = x;
  }
  fetchMore() async {
    lastPost = latestModel.results.last.s.id;
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
    currentSortTime = defaultSortTime;
    currentSortType = defaultSortType;
  }
  String getFilterString(){
    if(temporaryType == "top" || temporaryType == "controversial"){
      return temporaryType + " ● " + temporaryTime;
    }else{
      return temporaryType;
    }
  }
  var temporaryType = currentSortType;
  var temporaryTime = currentSortTime;

  String tempType = "";

}

final bloc = PostsBloc();