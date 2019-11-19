import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Blocs/bloc/posts_bloc.dart';
import 'package:lyre/Blocs/bloc/posts_state.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/UI/Comments/bloc/comments_bloc.dart';
import 'package:lyre/UI/Comments/bloc/comments_state.dart';
import 'package:lyre/UI/Comments/comment_list.dart';
import 'package:lyre/UI/posts_list.dart';

class RedditView extends StatelessWidget {
  final String query;

  const RedditView({Key key, this.query}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PostsProvider().getCRef('f6rmvk8'),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final CommentsBloc _commentsBloc = CommentsBloc(snapshot.data);
          return BlocProvider(
            builder: (context) => _commentsBloc,
            child: CommentList(),
          );
          /*
          if (data is Subreddit) {
            final PostsBloc _postsBloc = PostsBloc(firstState: PostsState(
              contentSource: ContentSource.Subreddit,
              userContent: [],
            ));
            return BlocProvider(
              builder: (context) => _postsBloc,
              child: PostsList("", ContentSource.Subreddit),
            );
          } else if (data is Redditor) {
            final PostsBloc _postsBloc = PostsBloc(firstState: PostsState(
              contentSource: ContentSource.Redditor,
              userContent: [],
              targetRedditor: data.displayName
            )); // ? Move these out of build function for sink management
            return BlocProvider(
              builder: (context) => _postsBloc,
              child: PostsList("", ContentSource.Subreddit),
            );
          } else if (data is Submission) {
            print(datadata.toString());
            final CommentsBloc _commentsBloc = CommentsBloc(CommentRef.withID(reddit, _id), datadata);
            return BlocProvider(
              builder: (context) => _commentsBloc,
              child: CommentList(),
            );
          } else {
            return Center(child: Text(data.toString()));
          }
          */
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString(), style: LyreTextStyles.errorMessage,),);
        } 
        return Center(child: CircularProgressIndicator(),);
      },
    );
  }
}