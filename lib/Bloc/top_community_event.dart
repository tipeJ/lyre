part of 'top_community_bloc.dart';

@immutable
abstract class TopCommunityEvent {}

class ChangeCategory extends TopCommunityEvent {
  final String category;

  ChangeCategory({this.category});
}