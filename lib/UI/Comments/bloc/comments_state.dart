import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class CommentsState extends Equatable {
  CommentsState([List props = const <dynamic>[]]) : super(props);
}

class InitialCommentsState extends CommentsState {}
