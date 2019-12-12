class SubredditM {
  List<_Result> _results = [];

  SubredditM.fromJson(List<dynamic> parsedJson) {
    List<_Result> temp = [];
    for (int i = 0; i < parsedJson.length; i++) {
      _Result result = _Result(parsedJson[i]);
      temp.add(result);
    }
    _results = temp;
  }

  List<_Result> get results => _results;
}
class _Result {

  String _title;
  String _displayName;
  String _url;
  int _subscribers;
  int _comment_score_hide_mins;
  int _accounts_active;
  bool _isNSFW;

  _Result(result) {
    _title = result['data']['title'];
    _displayName = result['data']['display_name'];
    _url = result['data']['url'];
    _subscribers = result['data']['subscribers'];
    _accounts_active = result['data']['accounts_active'];
    _comment_score_hide_mins = result['data']['comment_score_hide_mins'];
    _isNSFW = result['data']['over18'];
  }

  String get displayName => _displayName;

  String get url => _url;

  bool get isNSFW => _isNSFW;

  int get subscribers => _subscribers;

  String get title => _title;

  int get comment_score_hide_mins => _comment_score_hide_mins;

  int get accounts_active => _accounts_active;
}