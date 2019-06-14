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
  if(state == VoteState.none) return; //For efficiency, to prevent unnecessary calls to the API
  if(state == s.vote){
    s.clearVote();
  }else if(state == VoteState.downvoted){
    s.downvote();
  }else{
    s.upvote();
  }
}