import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../themes.dart';

@immutable
abstract class ThemeEvent extends Equatable {
  ThemeEvent([List props = const <dynamic>[]]) : super(props);
}

class ThemeChanged extends ThemeEvent{
  final LyreTheme theme;

  ThemeChanged({
    @required this.theme,
  }) : super([theme]);
}
