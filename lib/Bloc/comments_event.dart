import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class CommentsEvent extends Equatable {
  CommentsEvent([List props = const<dynamic>[]]);
}

class SortChanged extends CommentsEvent{
  final UserContent submission;
  final CommentSortType commentSortType;

  SortChanged({this.submission, this.commentSortType});

  List<dynamic> get props => [submission, commentSortType];
}

class RefreshComments extends CommentsEvent{
  RefreshComments();

  List<dynamic> get props => const [];
}

class FetchMoreComments extends CommentsEvent{
  final MoreComments moreComments;
  final int location;
  
  FetchMoreComments({
    @required this.moreComments,
    @required this.location,
  });

  List<dynamic> get props => [moreComments, location];
}

class Collapse extends CommentsEvent{
  final int location;
  
  Collapse({
    @required this.location,
  });
  List<dynamic> get props => [location];
}

class AddComment extends CommentsEvent{
  final int location;
  final Comment comment;
  
  AddComment({
    @required this.location,
    @required this.comment
  });
  List<dynamic> get props => [location, comment];
}
class ToggleSubmissionView extends CommentsEvent{
  ToggleSubmissionView();

  List<dynamic> get props => const [];
}
