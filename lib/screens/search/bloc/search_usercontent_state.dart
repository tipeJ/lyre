import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';

@immutable
class SearchUsercontentState extends Equatable {
  final bool loading;
  final List<dynamic> results;
  final PushShiftSearchParameters parameters;

  SearchUsercontentState({
    @required this.loading,
    @required this.results,
    @required this.parameters
  });

  List<dynamic> get props => [loading, results, parameters];
}