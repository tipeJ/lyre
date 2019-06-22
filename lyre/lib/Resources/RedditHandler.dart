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