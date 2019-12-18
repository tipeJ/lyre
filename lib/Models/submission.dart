import 'package:draw/draw.dart' as draw;
import 'package:lyre/Models/reddit_content.dart';
import 'package:lyre/utils/utils.dart';

class Submission extends RedditContent {

  Submission({
    this.fullname, 
    this.authorFlairText, 
    this.id,
    this.selftext,
    this.title,
    this.subreddit,
    this.author,
    this.body,
    this.domain,
    this.linkFlairText,

    this.score,
    this.numComments,
    this.gold,
    this.silver,
    this.platinum,

    this.upVoteRatio,

    this.hideScore,
    this.over18,
    this.spoiler,
    this.locked,
    this.quarantine,
    this.approved,
    this.edited,
    this.isSelf,
    this.isVideo,
    this.hidden,
    this.pinned,
    this.stickied,

    this.createdUTC,

    this.url,
    this.thumbnailUrl,

    this.linkType,

    this.previews,
    this.voteState
  });

  factory Submission.fromDraw(draw.Submission s) {
    return Submission(
      fullname: s.fullname,
      id: s.id,
      selftext: s.selftext,
      title: s.title,
      authorFlairText: s.authorFlairText,
      subreddit: s.subreddit.displayName,
      author: s.author,
      body: s.body,
      domain: s.domain,
      linkFlairText: s.linkFlairText,

      score: s.score,
      numComments: s.numComments,
      gold: s.gold,
      silver: s.silver,
      platinum: s.platinum,

      upVoteRatio: s.upvoteRatio,
      
      hideScore: s.hideScore,
      over18: s.over18,
      spoiler: s.spoiler,
      locked: s.locked,
      quarantine: s.quarantine,
      approved: s.approved,
      edited: s.edited,
      isSelf: s.isSelf,
      isVideo: s.isVideo,
      hidden: s.hidden,
      pinned: s.pinned,
      stickied: s.stickied,

      createdUTC: s.createdUtc,

      url: s.url,
      thumbnailUrl: s.thumbnail,

      linkType: getLinkType(s.url.toString()),

      previews: s.preview,
      voteState: s.vote
    );
  }

  @override
  String fullname;

  String id;

  String authorFlairText;

  String selftext;

  String title;

  String subreddit;

  String author;

  String body;

  String domain;

  String linkFlairText;

  int score;

  int numComments;

  int gold;

  int silver;

  int platinum;

  double upVoteRatio;

  bool hideScore;

  bool over18;

  bool spoiler;

  bool locked;

  bool quarantine;

  bool approved;

  bool edited;

  bool isSelf;

  bool isVideo;

  bool hidden;

  bool pinned;

  bool stickied;

  DateTime createdUTC;

  Uri url;

  Uri thumbnailUrl;

  LinkType linkType;

  List<draw.SubmissionPreview> previews;

  draw.VoteState voteState;
}