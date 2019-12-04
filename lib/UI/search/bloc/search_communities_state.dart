import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'bloc.dart';

@immutable
class SearchCommunitiesState extends Equatable {
  final bool loading;
  final List<dynamic> users;

  SearchCommunitiesState({
    @required this.loading,
    @required this.users,
  });
  List<dynamic> get props => [loading, users];
}
