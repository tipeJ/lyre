import 'package:equatable/equatable.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:meta/meta.dart';

@immutable
abstract class PostsEvent extends Equatable {
  PostsEvent([List props = const <dynamic>[]]) : super(props);
}

class PostsSourceChanged extends PostsEvent {
  final ContentSource source;
  final String typeFilter; //Will be converted to TypeFilter later in posts_bloc
  final String timeFilter;

  //Optional parameters:

  String redditor;
  SelfContentType selfContentType;

  PostsSourceChanged({
    this.typeFilter,
    this.timeFilter,
    this.source,

    //Optional parameters:

    this.redditor,
    this.selfContentType
  });
}

class FetchMore extends PostsEvent {
  
}