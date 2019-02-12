import 'Post.dart';

class ItemModel {
  int _page;
  int _total_results;
  int _total_pages;
  List<Post> _results = [];

  ItemModel.fromJson(List<dynamic> parsedJson) {
    print(parsedJson.length);
    /*_page = parsedJson['page'];
    _total_results = parsedJson['total_results'];
    _total_pages = parsedJson['total_pages'];*/
    List<Post> temp = [];
    for (int i = 0; i < parsedJson.length; i++) {
      Post result = Post(parsedJson[i]);
      temp.add(result);
    }
    _results = temp;
  }

  List<Post> get results => _results;

  int get total_pages => _total_pages;

  int get total_results => _total_results;

  int get page => _page;
}