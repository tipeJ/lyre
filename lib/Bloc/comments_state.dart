import 'package:basic_utils/basic_utils.dart';
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
  Comment parentComment;
  final List<CommentM> comments;
  final CommentSortType sortType;

  String get sortTypeString => StringUtils.capitalize(sortType.toString().split('.').last);

  CommentsState({
      @required this.state,
      @required this.submission,
      @required this.comments,
      @required this.sortType,
      this.parentComment
    });
    List<dynamic> get props => [state, comments, sortType, submission];
}
