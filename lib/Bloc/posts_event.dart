import 'package:draw/draw.dart';
import 'package:equatable/equatable.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:meta/meta.dart';

@immutable
abstract class PostsEvent extends Equatable {
  PostsEvent([List props = const <dynamic>[]]);
}

class PostsSourceChanged extends PostsEvent {
  final ContentSource source;
  final String typeFilter; //Will be converted to TypeFilter later in posts_bloc
  final String timeFilter;
  final dynamic target;

  //Optional parameters:

  PostsSourceChanged({
    this.typeFilter,
    this.timeFilter,
    this.source,
    this.target
  });
  List<dynamic> get props => [source, typeFilter, timeFilter, target];
}

class ParamsChanged extends PostsEvent{
  final TypeFilter typeFilter;
  final String timeFilter;

  ParamsChanged({
    @required this.typeFilter,
    @required this.timeFilter,
  }) : assert(typeFilter != null && timeFilter != null);

  List<dynamic> get props => [typeFilter, timeFilter];
}

class FetchMore extends PostsEvent {
  List<dynamic> get props => [];
}