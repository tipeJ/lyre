import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class CommentsEvent extends Equatable {
  CommentsEvent([List props = const<dynamic>[]]);
}

class SortChanged extends CommentsEvent{
  final Submission submission;
  final CommentSortType commentSortType;

  SortChanged(this.submission, this.commentSortType);

  List<dynamic> get props => [submission, commentSortType];
}
class FetchMore extends CommentsEvent{
  final MoreComments moreComments;
  final int location;
  
  FetchMore({
    @required this.moreComments,
    @required this.location,
  });

  List<dynamic> get props => [moreComments, location];
}
class Collapse extends CommentsEvent{
  final int location;
  final int depth;
  
  Collapse({
    @required this.location,
    @required this.depth,
  });
  List<dynamic> get props => [location, depth];
}
class CollapseX extends CommentsEvent{
  final Comment c;
  
  CollapseX({
    @required this.c,
  });
  List<dynamic> get props => [c];
}