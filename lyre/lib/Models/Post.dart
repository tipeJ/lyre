import '../utils/urlUtils.dart';
import 'package:draw/draw.dart';

class Post {
  Submission s;
  bool expanded = false;
  bool hasBeenViewed = false;

  SubmissionPreview _preview;

  LinkType _linkType;
  Post.fromApi(Submission s){
    this.s = s;

    _preview = s.preview.first;

    _linkType = s.isSelf ? LinkType.Self : getLinkType(s.url.toString());
  }
  SubmissionPreview get preview => _preview;
  
  LinkType get linkType => _linkType;

  String getUrl(){
    return s.url.toString();
  }
}