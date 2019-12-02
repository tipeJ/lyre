import 'dart:async';
import 'package:bloc/bloc.dart';
import './bloc.dart';

class SearchSubmissionsBloc extends Bloc<SearchSubmissionsEvent, List<dynamic>> {
  @override
  List<dynamic> get initialState => [];

  @override
  Stream<List<dynamic>> mapEventToState(
    SearchSubmissionsEvent event,
  ) async* {
    // TODO: Add Logic
  }
}
