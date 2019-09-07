import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class CommentsEvent extends Equatable {
  CommentsEvent([List props = const <dynamic>[]]) : super(props);
}
