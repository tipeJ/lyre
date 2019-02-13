class CommentM {
  List<_Result> _results = [];


  //recursion?
  CommentM.fromJson(List<dynamic> parsedJson) {
    /*print(parsedJson.length);
    List<_Result> temp = [];
    for (int i = 0; i < parsedJson.length; i++) {
      _Result result = _Result(parsedJson[i]);
      if(parsedJson[i]["data"].containsKey("replies") && parsedJson[i]["data"]["replies"] != "") {
        var replies = parsedJson[i]["data"]["replies"]["data"]["children"];
        CommentM.fromJson(replies);
      }
      temp.add(result);
    }*/
    addComments(parsedJson);
    //_results += temp;
  }

  List<_Result> get results => _results;

  void addComments(List<dynamic> jsonData){
    try {
      for (int i = 0; i < jsonData.length; i++) {
        if(jsonData[i]["kind"] != "t1")
          continue;

        _Result result = _Result(jsonData[i]);
        _results.add(result);
        if(jsonData[i]["data"].containsKey("replies") && jsonData[i]["data"]["replies"] != "") {
          var replies = jsonData[i]["data"]["replies"]["data"]["children"];
          addComments(replies);
        }
      }
    } catch(e) {
      print("ERROR: " + jsonData.toString());
    }

  }

}
class _Result {

  String _text;
  String _author;
  int _points;
  int _depth;

  _Result(result) {
    if(result == null){
      print('result is null');
    } else if(result["data"]["body"] == null){
      print('bofy is null');
    }
    _author = result['data']['author'];
    _points = result['data']['score'];
    _depth = result['data']['depth'];
    _text = result['data']['body'];
  }

  String get author => _author;

  int get points => _points;

  int get depth => _depth;

  String get text => _text;
}