import '../utils/urlUtils.dart';
import 'package:draw/draw.dart';

class Post {
  String _selftext;
  String _title;
  String _author;
  String _url;
  String _permalink;
  String _subreddit;
  int _comments;
  int _points;
  String _id;
  bool _self;
  bool expanded = false;
  bool hasBeenViewed = false;

  LinkType _linkType;

  Post(result) {
    _id = result['data']['id'];
    _title = result['data']['title'];
    _author = result['data']['author'];
    _url = result['data']['url'];
    _permalink = result['data']['permalink'];
    _points = result['data']['score'];
    _comments = result['data']['num_comments'];
    _self = result['data']['is_self'];
    _selftext = result['data']['selftext'];
    _subreddit = result['data']['subreddit'];

    _linkType = _self ? LinkType.Self : getLinkType(_url);
  }
  Post.fromApi(Submission s){
    _id = s.id;
    _title = s.title;
    _author = s.author;
    _url = s.url.toString();
    _permalink = s.shortlink.toString();
    _points = s.score;
    _comments = s.numComments;
    _self = s.isSelf;
    _selftext = s.selftext;
    _subreddit = s.subreddit.displayName;

    _linkType = _self ? LinkType.Self : getLinkType(_url);
  }
  
  LinkType get linkType => _linkType;

  String get subreddit => _subreddit;

  String get selftext => _selftext;

  String get author => _author;

  String get url => _url;

  bool get self => _self;

  String get permalink => _permalink;

  String get title => _title;

  String get id => _id;

  int get comments => _comments;

  int get points => _points;
}