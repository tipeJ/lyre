class ItemModel {
  int _page;
  int _total_results;
  int _total_pages;
  List<_Result> _results = [];

  ItemModel.fromJson(List<dynamic> parsedJson) {
    print(parsedJson.length);
    /*_page = parsedJson['page'];
    _total_results = parsedJson['total_results'];
    _total_pages = parsedJson['total_pages'];*/
    List<_Result> temp = [];
    for (int i = 0; i < parsedJson.length; i++) {
      _Result result = _Result(parsedJson[i]);
      temp.add(result);
    }
    _results = temp;
  }

  List<_Result> get results => _results;

  int get total_pages => _total_pages;

  int get total_results => _total_results;

  int get page => _page;
}
class _Result {

  String _title;
  String _author;
  String _url;
  String _permalink;
  int _comments;
  int _points;
  String _id;
  bool _self;

  _Result(result) {
    _id = result['data']['id'];
    _title = result['data']['title'];
    _author = result['data']['author'];
    _url = result['data']['url'];
    _permalink = result['data']['permalink'];
    _points = result['data']['score'];
    _comments = result['data']['num_comments'];
    _self = result['data']['is_self'];
  }

  String get author => _author;

  String get url => _url;

  bool get self => _self;

  String get permalink => _permalink;

  String get title => _title;

  String get id => _id;

  int get comments => _comments;

  int get points => _points;
}