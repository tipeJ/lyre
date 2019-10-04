import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../themes.dart';

@immutable
abstract class ThemeEvent extends Equatable {
  ThemeEvent();
}

class ThemeChanged extends ThemeEvent{
  final LyreTheme theme;

  ThemeChanged({
    @required this.theme,
  });
  List<dynamic> get props => [theme];
}
