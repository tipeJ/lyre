import 'dart:io';

import 'package:draw/draw.dart';
import 'reddit_api_provider.dart';
import '../UploadUtils/ImgurAPI.dart';

//---CHANGING SAVES, VOTING, ETC----
Future<void> changeSubmissionSave(Submission s) async {
  if(s.saved){
    return s.unsave();
  }else{
    return s.save();
  }
}

Future<void> changeCommentSave(Comment c) async {
  if(c.saved){
    return c.unsave();
  }else{
    return c.save();
  }
}

Future<void> changeSubmissionVoteState(VoteState state, Submission s) async {
  if(state == VoteState.none) return null; //For efficiency, to prevent unnecessary calls to the API
  if(state == s.vote){
    return s.clearVote();
  }else if(state == VoteState.downvoted){
    return s.downvote();
  }else{
    return s.upvote();
  }
}
Future<void> changeCommentVoteState(VoteState state, Comment c) async {
  if(state == VoteState.none) return null; //For efficiency, to prevent unnecessary calls to the API (shouldn't even happen, ever)
  if(state == c.vote){
    return c.clearVote();
  }else if(state == VoteState.downvoted){
    return c.downvote();
  }else{
    return c.upvote();
  }
}
//---SUBMISSIONS---
Future<dynamic> submitSelf(String sub, String title, String text, bool isNsfw, bool sendReplies) async {
  var r = await PostsProvider().getRed();
  var subRef = SubredditRef.name(r, sub);
  try {
    var x = await subRef.submit(
      title,
      selftext: text,
      nsfw: isNsfw,
      sendReplies: sendReplies
      );
    return r.submission(id: x.id).populate();
  } catch (e) {
    return e.toString();
  }
}
Future
<dynamic> submitLink(String sub, String title, String url, bool isNsfw, bool sendReplies) async {
  var r = await PostsProvider().getRed();
  var subRef = SubredditRef.name(r, sub);
  try {
    var x = await subRef.submit(
      title,
      url: url,
      nsfw: isNsfw,
      sendReplies: sendReplies
    );
    return r.submission(id: x.id).populate();
  } catch (e) {
    return e.toString();
  }  
}

Future<dynamic> submitImage(String sub, String title, bool isNsfw, bool sendReplies, File imageFile) async {
  try {
    var url = await ImgurAPI().uploadImage(imageFile, title);
    return submitLink(sub, title, url, isNsfw, sendReplies);
  } catch (e) {
    return e.toString();
  }  
}

Future<dynamic> reply(UserContent content, String body) async {
  try {
    if (content is Comment) {
      return content.reply(body);
    } else if (content is Submission) {
      return content.reply(body);
    }
  } catch (e) {
    return e.toString();
  }
}

Future<dynamic> report(UserContent content, String reason) async {
  try {
    if (content is Comment) {
      return content.report(reason);
    } else if (content is Submission) {
      return content.report(reason);
    }
  } catch (e) {
    return e.toString();
  }
}