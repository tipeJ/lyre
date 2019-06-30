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

    _preview = (s != null && s.preview.isNotEmpty) ? s.preview.first : null;

    _linkType = (s.isSelf == null || s.isSelf) ? LinkType.Self : getLinkType(s.url.toString());
  }
  SubmissionPreview get preview => _preview;
  
  LinkType get linkType => _linkType;

  String getUrl(){
    return s.url.toString();
  }
  Uri getImageUrl(){
    return (s.preview != null && s.preview.isNotEmpty) ? s.preview.first.source.url : null;
  }
  bool hasPreview(){
    return (s.preview != null && s.preview.isNotEmpty);
  }
}