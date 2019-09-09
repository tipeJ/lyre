import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class CommentsState extends Equatable {
  final CommentForest forest;
  final Submission submission;

  CommentsState({
    @required
    this.forest,
    @required
    this.submission
  }) : super([forest, submission]);
}