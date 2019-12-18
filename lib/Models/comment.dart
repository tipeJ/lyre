import 'package:draw/draw.dart' as draw;
import 'package:lyre/Models/reddit_content.dart';

class Comment extends RedditContent {

  Comment({
    this.fullname, 
    this.authorFlairText, 
    this.parentId,
  });

  factory Comment.fromDrawComment(draw.Comment comment) {
    return Comment(
      fullname: comment.fullname
    );
  }

  @override
  String fullname;

  String authorFlairText;

  String parentId;
}