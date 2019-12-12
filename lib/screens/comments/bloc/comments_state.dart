import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lyre/UI/comments/bloc/bloc.dart';
import 'package:meta/meta.dart';

@immutable
class CommentsState extends Equatable {
  final UserContent submission;
  Comment parentComment;
  final List<CommentM> comments;
  final CommentSortType sortType;

  CommentsState({
      @required this.submission,
      @required this.comments,
      @required this.sortType,
      this.parentComment
    });
    List<dynamic> get props => [comments, sortType, submission];
}
