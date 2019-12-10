import 'package:equatable/equatable.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';

abstract class SearchUsercontentEvent extends Equatable {
  const SearchUsercontentEvent();
}

class UserContentQueryChanged extends SearchUsercontentEvent {
  final PushShiftSearchParameters parameters;

  UserContentQueryChanged({this.parameters});

  @override
  List<dynamic> get props => [parameters];
}

class LoadMoreUserContent extends SearchUsercontentEvent {

  LoadMoreUserContent();

  @override
  List<dynamic> get props => [];
}