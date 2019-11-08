import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lyre/UI/Comments/bloc/bloc.dart';
import 'package:meta/meta.dart';

@immutable
class CommentsState extends Equatable {
  final List<CommentM> comments;
  final CommentSortType sortType;

  CommentsState({
      @required this.comments,
      @required this.sortType,
    });
    List<dynamic> get props => [comments, sortType];
}
