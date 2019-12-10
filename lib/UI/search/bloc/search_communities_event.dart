import 'package:equatable/equatable.dart';

abstract class SearchCommunitiesEvent extends Equatable {
  const SearchCommunitiesEvent();
}

class UserSearchQueryChanged extends SearchCommunitiesEvent {
  final String query;

  UserSearchQueryChanged({this.query});

  @override
  List<dynamic> get props => [query];
}
class LoadMoreCommunities extends SearchCommunitiesEvent {

  LoadMoreCommunities();

  @override
  List<dynamic> get props => [];
}