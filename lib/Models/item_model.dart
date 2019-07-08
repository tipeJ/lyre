import 'Post.dart';
import 'package:draw/draw.dart';

class ItemModel {
  int _page;
  int _total_results;
  int _total_pages;
  List<Post> _results = new List();

  ItemModel.fromApi(List<UserContent> list){
    List<Post> temp = [];
    for(int i = 0; i < list.length; i++){
      var userContent = list[i];
      if(userContent is Submission){
        temp.add(Post.fromApi(userContent));
      }
    }
    /*list.forEach((userContent) => () {
      print("STARTED IN USERCONTENT");
      print(userContent);
      if(userContent is Submission){
        print("IS SUB");
        temp.add(Post.fromApi(userContent));
      }
    });*/
    _results = temp;
  }

  List<Post> get results => _results;

  int get total_pages => _total_pages;

  int get total_results => _total_results;

  int get page => _page;
}