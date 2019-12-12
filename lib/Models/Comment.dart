import 'package:flutter/foundation.dart';
import 'package:draw/draw.dart';

class CommentM {
  List<commentResult> _results;
  CommentM.fromJson(List<dynamic> parsedJson) {
    _results  = new List();
    addComments(parsedJson);
  }
  CommentM.fromJson2(List<dynamic> parsedJson) {
    _results  = new List();
    addComments2(parsedJson);
  }
  

  List<commentResult> get results => _results;
  void addComments(List<dynamic> jsonData){
    try {
      for (int i = 0; i < jsonData.length; i++) {
        var x = jsonData[i];
        if(x is Comment){
          commentC result = commentC.fromC(x);
          result.c = x as Comment;
          _results.add(result);
          if(x.replies != null && x.replies.comments.isNotEmpty) {
            addComments(x.replies.comments);
          }
        }else if(x is MoreComments){
          var z = x as MoreComments;
          moreC c = new moreC(z.data);
          _results.add(c);
        }else{
          commentC result = commentC.fromC(x);
          result.c = x as Comment;
          _results.add(result);
        }
      }
    } catch(e) {
      debugPrint("ERRORSTRING: " + e.toString());
      //debugPrint("ERROR: " + jsonData.toString());
    }
  }
  void addComments2(List<dynamic> jsonData) {
    print("JSONDATA_LENGTH: " + jsonData.length.toString());
    debugPrint("TRIED: " + jsonData.toString());
    
      for (int i = 0; i < jsonData.length; i++) {
        var x = jsonData[i] as Comment;
        commentC result = commentC.fromC(jsonData[i]);
        result.c = x;
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
    } 
    if(result.containsKey("count")){
        count = result['count'];
      }
      if(result.containsKey("id")){
        id = result['id'];
      }
      if(result.containsKey("depth")){
        depth = result['depth'];
      }
      if(result.containsKey("children")){
        var chi = result['children'];
        for(int i = 0; i < chi.length; i++){
          children.add(chi[i]);
        }
      }
  }

}
class commentC extends commentResult{
  Comment c;
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
  set depth(int i){
    _depth = i;
  }
  String get id => _id;
  String get parent_id => _parent_id;

  String get author => _author;

  int get points => _points;

  int get depth => _depth;

  String get text => _text;
}