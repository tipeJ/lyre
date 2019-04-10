import 'package:draw/draw.dart';

class Commenter{
  List<Comment> comments = new List();

  Commenter.fromApi(List<Comment> replies){

    replies.forEach((comment)=>{
      comments.add(comment)
    });
    
  }
}