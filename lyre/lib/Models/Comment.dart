class CommentM {
  List<commentResult> _results;
  //recursion?
  CommentM.fromJson(List<dynamic> parsedJson) {
    _results  = new List();
    addComments(parsedJson);
    //_results += temp;
  }

  List<commentResult> get results => _results;

  void addComments(List<dynamic> jsonData){
    try {
      for (int i = 0; i < jsonData.length; i++) {
        if(jsonData[i]["kind"] == "t1"){
          commentC result = commentC(jsonData[i]);
          _results.add(result);
          if(jsonData[i]["data"].containsKey("replies") && jsonData[i]["data"]["replies"] != "") {
            var replies = jsonData[i]["data"]["replies"]["data"]["children"];
            addComments(replies);
          }
        }else if(jsonData[i]["kind"] == "more"){
          moreC c = new moreC(jsonData[i]);
          _results.add(c);
        }
      }
    } catch(e) {
      print("ERROR: " + jsonData.toString());
    }
  }

}
enum commentType{
  comment,
  more,
}
class commentResult {
  commentType type;
}
class moreC extends commentResult{
  List<String> children = new List();
  int count = 0;
  String id = "";
  int depth = 0;
  var type = commentType.more;

  moreC(result){
    if(result == null){
      print('result is null');
    } else if(result["data"]["children"] == null){
      print('children is null');
    }
    if(result.containsKey("data")){
      if(result["data"].containsKey("count")){
        count = result['data']['count'];
      }
      if(result["data"].containsKey("id")){
        id = result['data']['id'];
      }
      if(result["data"].containsKey("depth")){
        depth = result['data']['depth'];
      }
      if(result["data"].containsKey("children")){
        var chi = result['data']['children'];
        for(int i = 0; i < chi.length; i++){
          children.add(chi[i]);
        }
      }
    }
  }

}
class commentC extends commentResult{
  String _text = "";
  String _id = "";
  String _parent_id = "";
  String _author = "";
  int _points = 1;
  int _depth = -1;

  commentC(result) {
    if(result == null){
      print('result is null');
    } else if(result["data"]["body"] == null){
      print('bofy is null');
    }
    if(result.containsKey("data")){
      if(result["data"].containsKey("author")){
        _author = result['data']['author'];
      }
      if(result["data"].containsKey("score")){
        _points = result['data']['score'];
      }
      if(result["data"].containsKey("depth")){
        _depth = result['data']['depth'];
      }
      if(result["data"].containsKey("body")){
        _text = result['data']['body'];
      }
      if(result["data"].containsKey("parent_id")){
        _parent_id = result['data']['parent_id'];
      }
      if(result["data"].containsKey("link_id")){
        _id = result['data']['link_id'];
      }
    }
  }
  void set depth(int i){
    _depth = i;
  }
  String get id => _id;
  String get parent_id => _parent_id;

  String get author => _author;

  int get points => _points;

  int get depth => _depth;

  String get text => _text;
}