import 'package:flutter/material.dart';
import 'package:draw/draw.dart';

Color getScoreColor(VoteableMixin m, BuildContext context){
  switch (m.vote) {
      case VoteState.downvoted:
        return Colors.purple;
        break;
      case VoteState.upvoted:
        return Colors.amberAccent;
        break;
      default:
        return Theme.of(context).brightness == Brightness.dark ? Colors.blueGrey : Colors.black87;
    }
}
Duration getSubmissionAge(DateTime submittedAt){
  return DateTime.now().difference(submittedAt);
}