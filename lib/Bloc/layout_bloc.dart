import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'layout_event.dart';
part 'layout_state.dart';

class LayoutBloc extends Bloc<LayoutEvent, LayoutState> {
  @override
  LayoutState get initialState => LayoutInitial();

  @override
  Stream<LayoutState> mapEventToState(
    LayoutEvent event,
  ) async* {
    // TODO: Add Logic
  }
}
