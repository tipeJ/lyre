import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:meta/meta.dart';
import '../themes.dart';

@immutable
abstract class LyreEvent extends Equatable {
  LyreEvent();
}

class ThemeChanged extends LyreEvent{
  final LyreTheme theme;

  ThemeChanged({
    @required this.theme,
  });
  List<dynamic> get props => [theme];
}
class SettingsChanged extends LyreEvent{
  final Box settings;

  SettingsChanged({
    @required this.settings,
  });
  List<dynamic> get props => [settings];
}

