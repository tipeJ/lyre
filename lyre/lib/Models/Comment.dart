import 'package:flutter/foundation.dart';
import 'package:draw/draw.dart';

class CommentM {
  List<commentResult> _results;
  CommentM.fromJson(List<dynamic> parsedJson) {
    _results  = new List();
    addComments(parsedJson);
  }
  CommentM.fromJson2(List<dynamic> parsedJson, Reddit r) {
    _results  = new List();
    addComments2(parsedJson, r);
  }
  

  List<commentResult> get results => _results;

  void addComments(List<dynamic> jsonData){
    try {
      for (int i = 0; i < jsonData.length; i++) {
        if(jsonData[i]["kind"] == "t1"){
          commentC result = commentC(jsonData[i], false);
          _results.add(result);
          if(jsonData[i]["data"].containsKey("replies") && jsonData[i]["data"]["replies"] != "") {
            var replies = jsonData[i]["data"]["replies"]["data"]["children"];
            addComments(replies);
          }
        }else if(jsonData[i]["kind"] == "more"){
          moreC c = new moreC(jsonData[i]);
          _results.add(c);
        }else{
          commentC c = commentC(jsonData[i], false);
          _results.add(c);
        }
      }
    } catch(e) {
      debugPrint("ERRORSTRING: " + e.toString());
      debugPrint("ERROR: " + jsonData.toString());
    }
  }
  void addComments2(List<dynamic> jsonData, Reddit r) {
    print("JSONDATA_LENGTH: " + jsonData.length.toString());
    debugPrint("TRIED: " + jsonData.toString());
    
      for (int i = 0; i < jsonData.length; i++) {
        var x = jsonData[i] as Comment;
        commentC result = commentC.fromC(jsonData[i]);
        _results.add(result);
        print("LENGTHAESFASDF: " + _results.length.toString());
      }
  }

}
enum commentType{
  comment,
  more,
}
class commentResult {
  commentType type;
  bool visible = true;
  int depth;
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

  commentC.fromC(Comment comment){
      _author = comment.author;
      _points = comment.score;
      _id = comment.id;
      _parent_id = comment.parentId;
      _text = comment.body;
      _depth = comment.depth;
  }

  commentC(result, bool more) {
    if(result == null){
      print('result is null');
    }
    if(more){
        print("CLASS : " + result.runtimeType.toString());
        if(true){
           _author = result['author'];
        }
        if(true){
           _points = result['score'];
        }
        if(true){
            _depth = result['depth'];
        }
        if(true){
           _text = result['body'];
        }
        if(true){
            _parent_id = result['parent_id'];
        }
        if(true){
            _id = result['link_id'];
        }
    }else{
      if(result["data"]["body"] == null){
        print('body is null');
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