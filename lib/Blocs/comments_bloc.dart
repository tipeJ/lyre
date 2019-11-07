import '../Resources/repository.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/Comment.dart';

class CommentsBloc {
  final _repository = Repository();
  final _commentsFetcher = PublishSubject<CommentM>();
  CommentM currentComments;

  Observable<CommentM> get allComments => _commentsFetcher.stream;
  fetchComments() async {
    CommentM commentM = await _repository.fetchComments();
    currentComments = commentM;
    _commentsFetcher.sink.add(currentComments);
  }

  dispose() {
    _commentsFetcher.close();
  }
  getB(moreC more, int location, int depth, String link_id) async {
    print("STARTED MOREC");
    if(more.children == null || more.children.isEmpty){
      print("Nothing fetched from moreComments");
      return;
    }
    String resultList = "";
    for(int i = 0; i < more.children.length; i++){
      if(i != 0){
        resultList = resultList + ",";
      }
      resultList = resultList + more.children[i];
    }
    var model = await _repository.fetchComment(resultList, link_id);
    currentComments.results.removeAt(location);
    currentComments.results.insertAll(location, model.results);
    _commentsFetcher.sink.add(currentComments);
    loadingMoreId = "";
  }
  void changeVisibility(int index){
    commentResult upperComment = currentComments.results[index] as commentC;
    var blist = List<bool>();
    bool hasVisible = false;
    for(int i = index+1; true; i++){
      commentResult c = currentComments.results[i];
      if(i == index+1 && c.depth == upperComment.depth){
        return;
      }else if(c.depth == upperComment.depth){
        break;
      }
      blist.add(c.visible);
      if(c.visible){
        hasVisible = true;
      }
    }
    if(!hasVisible){
      for(int i = index+1; i <= index+blist.length; i++){
        currentComments.results[i].visible = true;
      }
    }else{
      for(int i = index+1; i <= index+blist.length; i++){
        currentComments.results[i].visible = false;
      }
    }
    _commentsFetcher.sink.add(currentComments);
  }
  bool isLoadingMore = false;
  String loadingMoreId = "";

}

final bloc = CommentsBloc();