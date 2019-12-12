import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
class SearchCommunitiesState extends Equatable {
  final bool loading;
  final List<dynamic> communities;
  final String query;

  SearchCommunitiesState({
    @required this.loading,
    @required this.communities,
    @required this.query
  });
  List<dynamic> get props => [loading, communities, query];
}
