import 'package:flutter/material.dart';
import 'package:draw/draw.dart';

Color getScoreColor(VoteableMixin m, BuildContext context){
  switch (m.vote) {
      case VoteState.downvoted:
        return Colors.purple;

      case VoteState.upvoted:
        return Colors.amberAccent;

      default:
        return Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87;
    }
}
CommentSortType parseCommentSortType(String sortString){
  switch (sortString) {
    case "Best":
      return CommentSortType.best;

    case "Confidence":
      return CommentSortType.confidence;
      
    case "Controversial":
      return CommentSortType.controversial;
      
    case "New":
      return CommentSortType.newest;
      
    case "Old":
      return CommentSortType.old;
      
    case "Q/A":
      return CommentSortType.qa;
      
    case "Random":
      return CommentSortType.random;
      
    case "Top":
      return CommentSortType.top;
      
    default:
      return CommentSortType.blank; //Default to blank
  }
}
String getSubmissionAge(DateTime submittedAt){
  // ? Probably inaccurate at times due to excessive rounding? Implement a better method later (never)
  var difference = DateTime.now().difference(submittedAt);

  //How accurately should the submission age be shown based on age difference.
  if(difference.inSeconds < 60){
    //Accuracy is one minute
    return 'now';
  } else if(difference.inMinutes < 60){
    //Nothing is needed between a minute and an hour
    return 'less than an hour ago';
  } else if(difference.inHours < 24){
    //Accuracy is one hour
    return '${difference.inHours} hours ago';
  } else if(difference.inDays < 7){
    //Accuracy is one day
    return '${difference.inDays} days ago';
  } else if(difference.inDays < 31){
    //Accuracy is (roughly) one week floored down to the previous whole week
    return '${(difference.inDays / 7).floor()} weeks ago';
  } else if(difference.inDays < 365){
    //Logic same as in the week argument, except for months (Avg.month length is 31 days).
    return '${(difference.inDays / (365 / 12)).floor()} months ago';
  } else{
    //Logic same as before, except for years.
    return '${(difference.inDays / 365).floor()} years ago';
  }
}