import 'package:flutter/material.dart';
import 'package:draw/draw.dart';

Color getScoreColor(VoteableMixin m){
  switch (m.vote) {
      case VoteState.downvoted:
        return Colors.purple;
        break;
      case VoteState.upvoted:
        return Colors.amberAccent;
        break;
      default:
        return Colors.blueGrey;
    }
}