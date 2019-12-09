import 'package:equatable/equatable.dart';

abstract class SearchUsercontentState extends Equatable {
  const SearchUsercontentState();
}

class InitialSearchUsercontentState extends SearchUsercontentState {
  @override
  List<Object> get props => [];
}
