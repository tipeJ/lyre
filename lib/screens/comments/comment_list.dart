import 'dart:async';

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/RedditHandler.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/comment.dart';
import 'package:lyre/widgets/bottom_appbar.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/widgets/postInnerWidget.dart';
import 'package:lyre/widgets/widgets.dart';
import '../../Resources/globals.dart';
import 'package:lyre/Bloc/bloc.dart';

const selection_image = "Image";
const selection_album = "Album";

///Enum for selected comment options params
enum _CommentSelectionVisibility {
  Default,
  Copy,
}

class CommentList extends StatefulWidget {
  final VoidCallback backButtonCallback;
  const CommentList({this.backButtonCallback});

  @override
  CommentListState createState() => CommentListState();
}


class CommentListState extends State<CommentList> with SingleTickerProviderStateMixin{

  CommentListState();

  CommentsBloc _bloc;

  Comment _selectedComment;
  _CommentSelectionVisibility _commentSelectionVisibility;
  PersistentBottomSheetController _bottomSheetController;
  
  Completer<void> _refreshCompleter;

  @override
  void initState() { 
    super.initState();
    _refreshCompleter = Completer<void>();
  }
  
  @override
  void dispose() { 
    _bloc.close();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    _bloc = BlocProvider.of<CommentsBloc>(context);
    if((_bloc.state == null || _bloc.state.comments.isEmpty) && _bloc.state.state == LoadingState.Inactive){
      _bloc.add(SortChanged(submission: _bloc.initialState.submission, commentSortType: parseCommentSortType(BlocProvider.of<LyreBloc>(context).state.defaultCommentsSort)));
    }
    return Scaffold(
        endDrawer: Drawer(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: BlocBuilder<LyreBloc, LyreState>(
              builder: (context, state) {
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight, top: 10.0),
                  itemCount: recentlyViewed.length+1,
                  itemBuilder: (context, i){
                    return i == 0
                      ? const Text(
                        "Recently Viewed",
                        style: TextStyle(
                          fontSize: 26.0,
                        ),
                      )
                      : postInnerWidget(
                          submission: recentlyViewed[i-1], 
                          previewSource: PreviewSource.Comments,
                          postView: PostView.NoPreview,
                          fullSizePreviews: state.fullSizePreviews,
                          showCircle: state.showPreviewCircle,
                          blurLevel: state.blurLevel.toDouble(),
                          showNsfw: state.showNSFWPreviews,
                          showSpoiler: state.showSpoilerPreviews,
                          onOptionsClick: () {},
                        );
                  },
                );
              },
            ),
          ),
        ),
        body: NotificationListener<CommentOptionsNotification>(
          onNotification: (notification) {
            _initializeCommentOptions(notification.comment, context);
            return false;
          },
          child: BlocBuilder<CommentsBloc, CommentsState>(
            builder: (_, state) => LayoutBuilder(builder: (context, constraints) {
              if (wideLayout(constraints: constraints) && _bloc.state.submission is Submission) {
                final sub = _bloc.state.submission as Submission;
                if (sub.isSelf && sub.selftext.isEmpty) return _getPortraitLayout(context, state);
                return _getLandscapeLayout(context, state);
              }
              return _getPortraitLayout(context, state);
            }
            )
          )
        )
      );
  }

  Widget _getPortraitLayout (BuildContext context, CommentsState state) => PersistentBottomAppbarWrapper(
    body: _commentsList(context, state),
    appBarContent: BlocBuilder<CommentsBloc, CommentsState> (
      builder: (context, state) => _CommentsBottomBar(state: state)
    ),
  );

  Widget _getLandscapeLayout (BuildContext context, CommentsState state) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      mat.Visibility(
        visible: state.showSubmission,
        child: Flexible(
          flex: 2,
          child: ExpandedPostWidget(submission: state.submission)
        )
      ),
      Flexible(
        flex: 5,
        child: RefreshIndicator(
          onRefresh: () {
            BlocProvider.of<CommentsBloc>(context).add(RefreshComments());
            return _refreshCompleter.future;
          },
          child: Builder(
            builder: (context) {
              if (state.comments.isNotEmpty && state.state != LoadingState.Refreshing) {
                _refreshCompleter?.complete();
                _refreshCompleter = Completer<void>();
                return _getCommentWidgetsWithOptionsHeader(context, state.comments);
              } else if (state.comments.isEmpty && state.state == LoadingState.Refreshing) {
                return const Center(child: CircularProgressIndicator());
              }
              return _getCommentWidgetsWithOptionsHeader(context, state.comments);
            }
          ),
        )
      )
    ]
  );

  Widget _commentsList(BuildContext context, CommentsState state) => NestedScrollView(
    headerSliverBuilder: (context, innerBoxScrolled) => [
      SliverSafeArea(
        sliver: SliverToBoxAdapter(
          child: notNull(state) && state.submission is Submission
            ? Hero(
                tag: 'post_hero ${(state.submission as Submission).id}',
                child: postInnerWidget(
                  submission: state.submission,
                  previewSource: PreviewSource.Comments,
                  linkType: getLinkType((state.submission as Submission).url.toString()),
                  fullSizePreviews: false,
                  postView: PostView.ImagePreview,
                  showCircle: false,
                  blurLevel: 0.0,
                  showNsfw: true,
                  showSpoiler: true,
                  onOptionsClick: () {},
                )
              )
            : const SizedBox()
        ),
      )
    ],
    body: RefreshIndicator(
      onRefresh: () {
        BlocProvider.of<CommentsBloc>(context).add(RefreshComments());
        return _refreshCompleter.future;
      },
      child: Builder(
        builder: (context) {
          if (state.comments.isNotEmpty && state.state != LoadingState.Refreshing) {
            _refreshCompleter?.complete();
            _refreshCompleter = Completer<void>();
            return _getCommentWidgets(context, state.comments);
          } else if (state.comments.isEmpty && state.state == LoadingState.Refreshing) {
            return const Center(child: CircularProgressIndicator());
          }
          return _getCommentWidgets(context, state.comments);
        }
      ),
    )
  );

  Widget _getCommentWidgets(BuildContext context, List<dynamic> list){
    return ListView.builder(
      padding: const EdgeInsets.only(top: 5.0, bottom: kBottomNavigationBarHeight),
      itemBuilder: (context, i) {
          return BlocBuilder<CommentsBloc, CommentsState>(
            builder: (BuildContext context, state) {
              return mat.Visibility(
                child: _getCommentWidget(context, state.comments[i].c, i,),
                visible: state.comments[i].visible,
              );
            },
          );
      }, itemCount: list.length);
  }

  Widget _getCommentWidgetsWithOptionsHeader(BuildContext context, List<dynamic> list){
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          automaticallyImplyLeading: false,
          floating: true,
          title: SubmissionDetailsAppBar(submission: _bloc.state.submission),
          actions: const [],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => mat.Visibility(
              child: _getCommentWidget(context, list[i].c, i,),
              visible: list[i].visible,
            ),
            childCount: list.length
          ),
        )
      ],
    );
  }

  Widget _getCommentWidget(BuildContext context, dynamic comment, int i) {
    if (comment is Comment) {
      return CommentWidget(
        comment, i, 
        PreviewSource.Comments,
        onTap: () {
          setState(() {
            BlocProvider.of<CommentsBloc>(context).add(Collapse(location: i)); 
            });
        },
        onLongPress: () {
          _initializeCommentOptions(comment, context);
        }
      );
    } else {
      return MoreCommentsWidget(comment, i);
    }
  }

  _initializeCommentOptions(Comment comment, BuildContext context) {
    _selectedComment = comment;
    _commentSelectionVisibility = _CommentSelectionVisibility.Default;
    _bottomSheetController = Scaffold.of(context).showBottomSheet(
      (context) => Material(
        textStyle: Theme.of(context).textTheme.body1,
        color: Colors.transparent,
        child: _commentOptionsSheet(context)
      )
    );
  }

  Widget _commentOptionsSheet(BuildContext context) =>
    Column(
        mainAxisSize: MainAxisSize.min,
        children: _commentSelectionVisibility == _CommentSelectionVisibility.Default
          ? [
            ActionSheetTitle(
              title: _selectedComment.body,
            ),
            ActionSheetInkwell(
              title: const Text("Share Comment"),
              onTap: () {
                shareString(urlFromPermalink(_selectedComment.permalink));
              },
            ),
            ActionSheetInkwell(
              title: const Text("Open In Browser"),
              onTap: () {
                launchURL(context, _selectedComment.permalink);
              },
            ),
            ActionSheetInkwell(
              title: const Text("Copy"),
              onTap: () {
                _bottomSheetController.setState((){
                  _commentSelectionVisibility = _CommentSelectionVisibility.Copy;
                });
              },
            ),
          ]
          : [
            ActionSheetTitle(
              title: "Copy",
              actionCallBack: () {
                _bottomSheetController.setState((){
                  _commentSelectionVisibility = _CommentSelectionVisibility.Default;
                });
              },
            ),
            ActionSheetInkwell(
              title: const Text("URL"),
              onTap: () {
                copyToClipboard(urlFromPermalink(_selectedComment.permalink));
                Navigator.of(context).pop();
              },
            ),
            ActionSheetInkwell(
              title: const Text("Text"),
              onTap: () {
                copyToClipboard(_selectedComment.body);
                Navigator.of(context).pop();
              },
            ),
            ActionSheetInkwell(
              title: const Text("Username"),
              onTap: () {
                copyToClipboard(_selectedComment.author);
                Navigator.of(context).pop();
              },
            ),
          ]
      );
  
}
enum _CommentsBottomBarVisibility {
  Default,
  QuickReply
}

class _CommentsBottomBar extends StatefulWidget {
  final CommentsState state;

  const _CommentsBottomBar({@required this.state, Key key}) : super(key: key);

  @override
  __CommentsBottomBarState createState() => __CommentsBottomBarState();
}

class __CommentsBottomBarState extends State<_CommentsBottomBar> {
  _CommentsBottomBarVisibility _barVisibility = _CommentsBottomBarVisibility.Default;
  SendingState _replySendingState = SendingState.Inactive;
  String _replyErrorMessage = "";

  TextEditingController _replyController;

  @override
  void initState() { 
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() { 
    _replyController.dispose();
    super.dispose();
  }

  Future<bool> _willPop() {
    if (_barVisibility == _CommentsBottomBarVisibility.Default) return Future.value(true);
    setState(() {
      _barVisibility = _CommentsBottomBarVisibility.Default;
    });
    return Future.value(false);
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPop,
      child: notNull(widget.state) && widget.state.parentComment == null
        ? Column(
            children: [
              AnimatedContainer(
                duration: appBarContentTransitionDuration,
                height: _barVisibility == _CommentsBottomBarVisibility.Default ? kBottomNavigationBarHeight : 0.0,
                curve: Curves.ease,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Material(
                      color: Colors.transparent,
                      child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context),)
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Scaffold.of(context).showBottomSheet((context) => _sortParamsSheet(context));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                "${widget.state.comments.length} Comments",
                                style: Theme.of(context).textTheme.title,
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(text: widget.state.sortTypeString()),
                                    TextSpan(text: widget.state.submission is Submission
                                      ? " | ${(widget.state.submission as Submission).subreddit.displayName}"
                                      : "")
                                  ]
                                ),
                                style: LyreTextStyles.timeParams.apply(
                                  color: Theme.of(context).textTheme.display1.color
                                ),
                              ),
                            ],
                          )
                        )
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: IconButton(icon: const Icon(Icons.reply), tooltip: "Reply", onPressed: () {
                        setState(() {
                          _barVisibility = _CommentsBottomBarVisibility.QuickReply;
                        });
                      })
                    ),
                  ],
                )
              ),
              AnimatedContainer(
                duration: appBarContentTransitionDuration,
                height: _barVisibility == _CommentsBottomBarVisibility.QuickReply ? kBottomNavigationBarHeight : 0.0,
                curve: Curves.ease,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: mat.Visibility(
                          visible: _barVisibility == _CommentsBottomBarVisibility.QuickReply,
                          child: _replySendingState == SendingState.Error
                            ? Text(_replyErrorMessage ?? "Error Sending Reply")
                            : mat.Visibility(
                              visible: _replySendingState != SendingState.Error,
                                child: TextField(
                                  enabled: _barVisibility == _CommentsBottomBarVisibility.QuickReply && _replySendingState == SendingState.Inactive,
                                  autofocus: true,
                                  controller: _replyController,
                                  decoration: InputDecoration.collapsed(hintText: 'Reply'),
                              )
                            )
                        ),
                      ),
                      IconButton(
                        icon: _replySendingState == SendingState.Error
                          ? Icon(Icons.refresh)
                          : Icon(Icons.fullscreen),
                        onPressed: () {
                          if (_replySendingState == SendingState.Error) {
                            setState(() {
                              _replySendingState = SendingState.Inactive;
                            });
                          } else if (_replySendingState == SendingState.Inactive) {
                            // Expand quickreply to a full Reply window
                            Navigator.pushNamed(context, 'reply', arguments: {
                              'content'        : BlocProvider.of<CommentsBloc>(context).state.submission,
                              'reply_text'  : _replyController?.text
                            }).then((returnValue) {
                              if (returnValue is Comment) {
                                // Successful return
                              } else {
                                setState(() {
                                  _replySendingState = SendingState.Inactive;
                                  _barVisibility = _CommentsBottomBarVisibility.Default;
                                });
                              }
                            }); 
                          }
                        },
                      ),
                      IconButton(
                        icon: _replyTrailingAction(),
                        onPressed: () {
                          if (_replySendingState == SendingState.Inactive) {
                            if (_replyController?.text.isEmpty) {
                              final emptyTextSnackBar = const SnackBar(
                                content: Text("Cannot Send an Empty Reply"),
                                duration: Duration(seconds: 1),
                              );
                              Scaffold.of(context).showSnackBar(emptyTextSnackBar);
                              return;
                            }

                            setState(() {
                              _replySendingState = SendingState.Sending;
                            });

                            reply(BlocProvider.of<CommentsBloc>(context).state.submission, _replyController.text).then((returnValue) {
                              // Show error message if return value is a string (an error), or dismiss QuickReply window.
                              if (returnValue is String) {
                                // Error
                                setState(() {
                                  _replySendingState = SendingState.Error;
                                  _replyErrorMessage = returnValue;
                                });
                              } else {
                                // Success
                                setState(() {
                                  _barVisibility = _CommentsBottomBarVisibility.Default;
                                    _replySendingState = SendingState.Inactive;
                                });
                              }
                            });
                          } else if (_replySendingState == SendingState.Error) {
                            setState(() {
                             _barVisibility = _CommentsBottomBarVisibility.Default;
                              _replySendingState = SendingState.Inactive;
                            });
                          }
                        },
                      )
                    ],
                  )
                )
              )
            ]
          )
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    "You are viewing a single comment",
                    maxLines: 1,
                    style: Theme.of(context).primaryTextTheme.body1,
                    overflow: TextOverflow.ellipsis,
                  )
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: FlatButton(
                    textColor: Theme.of(context).primaryTextTheme.body1.color,
                    child: Text(
                      "View All Comments",
                    ),
                    onPressed: (){
                      BlocProvider.of<CommentsBloc>(context).add(SortChanged(submission: widget.state.submission, commentSortType: CommentSortType.top));
                    },
                  )
                )
              ],
            )
          )
    );
              
  }

  Widget _replyTrailingAction() {
    if (_replySendingState == SendingState.Inactive) { //Submit icon
      return Icon(Icons.send);
    } else if (_replySendingState == SendingState.Sending) { // Loading indicator
      return CircularProgressIndicator();
    }
    //Error widget:
    return Icon(Icons.close);
  }

  Widget _sortParamsSheet(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: List<Widget>.generate(commentSortTypes.length, (int index) => 
      index == 0
        ? const ActionSheetTitle(title: "Sort")
        : ActionSheetInkwell(
            title: Row(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 5.0),
                child: Icon(getCommentsSortIcon(commentSortTypes[index-1]))
              ),
              Text(commentSortTypes[index-1])
            ]),
            onTap: () {
              BlocProvider.of<CommentsBloc>(context).add(SortChanged(commentSortType: parseCommentSortType(commentSortTypes[index-1])));
              Navigator.of(context).pop();
            },
          )
    ),
  );
}