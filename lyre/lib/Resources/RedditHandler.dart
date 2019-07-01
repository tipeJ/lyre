import 'package:draw/draw.dart';
import 'reddit_api_provider.dart';

Future<void> changeSave(Submission s) async {
  if(s.saved){
    return s.unsave();
  }else{
    return s.save();
  }
}
Future<void> changeVoteState(VoteState state, Submission s) async {
  if(state == VoteState.none) return null; //For efficiency, to prevent unnecessary calls to the API
  if(state == s.vote){
    return s.clearVote();
  }else if(state == VoteState.downvoted){
    return s.downvote();
  }else{
    return s.upvote();
  }
}
//---SUBMISSIONS---
Future<Submission> submitSelf(String sub, String title, String text, bool isNsfw, bool sendReplies) async {
  var r = await PostsProvider().getRed();
  var subRef = SubredditRef.name(r, sub);
  var x = await subRef.submit(
    title,
    selftext: text,
    nsfw: isNsfw,
    sendReplies: sendReplies
     );
  return r.submission(id: x.id).populate();
}
Future<Submission> submitLink(String sub, String title, String url, bool isNsfw, bool sendReplies) async {
  var r = await PostsProvider().getRed();
  var subRef = SubredditRef.name(r, sub);
  var x = await subRef.submit(
    title,
    url: url,
    nsfw: isNsfw,
    sendReplies: sendReplies
     );
  return r.submission(id: x.id).populate();
}