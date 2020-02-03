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
class UserChanged extends LyreEvent{
  final String userName;

  UserChanged({
    @required this.userName,
  });
  List<dynamic> get props => [userName];
}
class Subscribe extends LyreEvent{
  final String subreddit;

  Subscribe({
    @required this.subreddit,
  }) : assert(subreddit != null);

  List<dynamic> get props => [subreddit];
}
class UnSubscribe extends LyreEvent {
  final String subreddit;

  UnSubscribe({
    @required this.subreddit,
  }) : assert(subreddit != null);

  List<dynamic> get props => [subreddit];
}
class ChangeSubscription extends LyreEvent {
  final String subreddit;

  ChangeSubscription({
    @required this.subreddit,
  }) : assert(subreddit != null);

  List<dynamic> get props => [subreddit];
}