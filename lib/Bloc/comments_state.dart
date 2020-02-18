import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'bloc.dart';
import 'package:lyre/Resources/globals.dart';

@immutable
class CommentsState extends Equatable {
  final LoadingState state;
  final UserContent submission;
  final Comment parentComment;
  final List<CommentM> comments;
  final CommentSortType sortType;

  /// If disabled, the submission view next to the comments list is hidden.
  /// Only available in landscape expanded mode.
   bool showSubmission;

  String sortTypeString() {
    switch (sortType) {
      case CommentSortType.best:
        return "Best";

      case CommentSortType.confidence:
        return "Confidence";
        
      case CommentSortType.controversial:
        return "Controversial";
        
      case CommentSortType.newest:
        return "New";
        
      case CommentSortType.old:
        return "Old";
        
      case CommentSortType.qa:
        return "Q/A";
        
      case CommentSortType.random:
        return "Random";
        
      case CommentSortType.top:
        return "Top";
        
      default:
        return ""; //Default to blank
    }
  }

   CommentsState({
      @required this.state,
      @required this.submission,
      @required this.comments,
      @required this.sortType,
      this.showSubmission = true,
      this.parentComment
    });
  List<dynamic> get props => [state, comments, sortType, submission, showSubmission];
}
