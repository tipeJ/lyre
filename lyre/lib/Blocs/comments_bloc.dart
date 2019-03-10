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
    var resultList = new List<commentResult>();
    for(int i = 0; i < more.children.length; i++){
      var v = await _repository.fetchComment(more.children[i]);
      print("CLENGTH:" + v.results.length.toString());
      resultList.add(v.results.first);
      /*v.results.forEach((result) =>(){
        resultList.add(result);
      });*/
    }
    for(int i = 0; i < resultList.length; i++){
      if(resultList[i] is commentC){
        (resultList[i] as commentC).depth = depth;
      }else if(resultList[i] is moreC){
        (resultList[i] as moreC).depth = depth;
      }
    }
    print("LEHGTH:" + resultList.length.toString());
    print("BEFIRE:" + currentComments.results.length.toString());
    currentComments.results.removeAt(location);
    currentComments.results.insertAll(location, resultList);
    print("AFTERR:" + currentComments.results.length.toString());
    _commentsFetcher.sink.add(currentComments);
  }

}

final bloc = CommentsBloc();