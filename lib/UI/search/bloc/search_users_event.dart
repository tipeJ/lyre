import 'package:equatable/equatable.dart';

abstract class SearchUsersEvent extends Equatable {
  const SearchUsersEvent();
}

class UserSearchQueryChanged extends SearchUsersEvent {
  final String query;

  UserSearchQueryChanged({this.query});

  @override
  List<dynamic> get props => [query];

}