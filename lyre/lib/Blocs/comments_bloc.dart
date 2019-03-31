import '../Resources/repository.dart';
import 'package:rxdart/rxdart.dart';
import '../Models/item_model.dart';
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
  getComments(String id, int location, int depth) async {
    print("STARTED");
    var v = await _repository.fetchComment(id);
    for(int i = 0; i < v.results.length; i++){
      if(v.results[i] is commentC){
        (v.results[i] as commentC).depth = depth;
      }else if(v.results[i] is moreC){
        (v.results[i] as moreC).depth = depth;
      }
    }
    print("LEHGTH:" + v.results.length.toString());
    print("BEFIRE:" + currentComments.results.length.toString());
    currentComments.results.removeAt(location);
    currentComments.results.insertAll(location, v.results);
    print("AFTERR:" + currentComments.results.length.toString());
    _commentsFetcher.sink.add(currentComments);
    print("ENDED");
  }
  getB(moreC more, int location, int depth) async {
    print("STARTED MOREC");
    if(more.children == null || more.children.isEmpty){
      print("Nothing fetched from moreComments");
      return;
    }
    print("FGEWFWE:" + more.children.length.toString());
    var resultList = "";
    for(int i = 0; i < more.children.length; i++){
      //var v = await _repository.fetchComment(more.children[i]);
      if(i != 0){
        resultList += "+";
      }
      resultList+=(more.children[i]);
      /*v.results.forEach((result) =>(){
        resultList.add(result);
      });*/
    }
    var x = await _repository.fetchComment(resultList);
    print("FF:$resultList");
    for(int i = 0; i < x.results.length; i++){
      if(x.results[i] is commentC){
        (x.results[i] as commentC).depth = depth;
      }else if(x.results[i] is moreC){
        (x.results[i] as moreC).depth = depth;
      }
    }
    print("LEHGTH:" + resultList.length.toString());
    print("BEFIRE:" + currentComments.results.length.toString());
    currentComments.results.removeAt(location);
    currentComments.results.insertAll(location, x.results);
    print("AFTERR:" + currentComments.results.length.toString());
    _commentsFetcher.sink.add(currentComments);
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

}

final bloc = CommentsBloc();