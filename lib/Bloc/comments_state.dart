import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'bloc.dart';

@immutable
class CommentsState extends Equatable {
  final LoadingState state;
  final UserContent submission;
  Comment parentComment;
  final List<CommentM> comments;
  final CommentSortType sortType;

  CommentsState({
      @required this.state,
      @required this.submission,
      @required this.comments,
      @required this.sortType,
      this.parentComment
    });
    List<dynamic> get props => [state, comments, sortType, submission];
}
