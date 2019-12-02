import 'package:equatable/equatable.dart';

abstract class SearchSubmissionsEvent extends Equatable {
  const SearchSubmissionsEvent();
}

class SubmissionsParamsChanged extends SearchSubmissionsEvent {
  final String query;

  SubmissionsParamsChanged({this.query});

  @override
  List<dynamic> get props => [query];

}