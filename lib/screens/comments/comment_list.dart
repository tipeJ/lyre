import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/comment.dart';
import 'package:lyre/widgets/bottom_appbar.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/widgets/postInnerWidget.dart';
import 'package:lyre/widgets/widgets.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../../Resources/globals.dart';
import 'package:lyre/Bloc/bloc.dart';

const selection_image = "Image";
const selection_album = "Album";

enum _CommentSelectionVisibility {
  Default,
  Copy,
}

class CommentList extends StatefulWidget {

  CommentList();

  @override
  CommentListState createState() => CommentListState();
}


class CommentListState extends State<CommentList> with SingleTickerProviderStateMixin{

  CommentListState();

  Comment _selectedComment;
  _CommentSelectionVisibility _commentSelectionVisibility;
  PersistentBottomSheetController _bottomSheetController;
  
  @override
  void dispose() { 
    BlocProvider.of<CommentsBloc>(context).close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<CommentsBloc>(context);
    if((bloc.state == null || bloc.state.comments.isEmpty) && bloc.state.state == LoadingState.Inactive){
      bloc.add(SortChanged(submission: bloc.initialState.submission, commentSortType: parseCommentSortType(BlocProvider.of<LyreBloc>(context).state.defaultCommentsSort)));
    }
    return Scaffold(
        endDrawer: Drawer(
          child: Container(
            padding: const EdgeInsets.all(10.0),
            child: BlocBuilder<LyreBloc, LyreState>(
              builder: (context, state) {
                return ListView.builder(
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
                          postView: PostView.Compact,
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
        body: PersistentBottomAppbarWrapper(
          body: NotificationListener<CommentOptionsNotification>(
              onNotification: (notification) {
                _initializeCommentOptions(notification.comment, context);
                return false;
              },
              child: CustomScrollView(
                slivers: <Widget>[
                  BlocBuilder<CommentsBloc, CommentsState>(
                    builder: (context, state) {
                      return SliverSafeArea(
                      sliver: SliverToBoxAdapter(
                        child: notNull(state) && state.submission is Submission
                          ? Hero(
                              tag: 'post_hero ${(state.submission as Submission).id}',
                              child: postInnerWidget(
                                submission: state.submission,
                                previewSource: PreviewSource.Comments,
                                linkType: getLinkType((state.submission as Submission).url.toString()),
                                fullSizePreviews: false,
                                postView: PostView.IntendedPreview,
                                showCircle: false,
                                blurLevel: 0.0,
                                showNsfw: true,
                                showSpoiler: true,
                                onOptionsClick: () {},
                              )
                            )
                          : const SizedBox()
                      ),
                    );
                    },
                  ),
                  BlocBuilder<CommentsBloc, CommentsState>(
                    builder: (context, state) => state.comments.isNotEmpty && state.state != LoadingState.Refreshing
                      ? _getCommentWidgets(context, state.comments)
                      : const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Center(
                            child: CircularProgressIndicator()
                          )
                        ),
                      )
                  ),
                ],
              )
            ),
            appBarContent: BlocBuilder<CommentsBloc, CommentsState> (
              builder: (context, state) {
                return notNull(state) && state.parentComment == null
                  ? Row(
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
                                  "${state.comments.length} Comments",
                                  style: Theme.of(context).textTheme.title,
                                ),
                                Text(
                                  state.sortTypeString,
                                  style: LyreTextStyles.timeParams.apply(
                                    color: Theme.of(context).textTheme.display1.color
                                  ),
                                ),
                              ],
                            )
                          )
                        ),
                      ),
                    ],
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
                                BlocProvider.of<CommentsBloc>(context).add(SortChanged(submission: state.submission, commentSortType: CommentSortType.top));
                              },
                            )
                          )
                        ],
                      )
                    );
              }
            ),
          )
        );
  }

  Widget _getCommentWidgets(BuildContext context, List<dynamic> list){
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int i){
          return BlocBuilder<CommentsBloc, CommentsState>(
            builder: (BuildContext context, state) {
              return prefix0.Visibility(
                child: _getCommentWidget(context, state.comments[i].c, i,),
                visible: state.comments[i].visible,
              );
            },
          );
      }, childCount: list.length),
    );
  }

  Widget _getCommentWidget(BuildContext context, dynamic comment, int i) {
    if (comment is Comment) {
      return InkWell(
        child: CommentWidget(comment, i, PreviewSource.Comments),
        onLongPress: () {
          _initializeCommentOptions(comment, context);
        },
        onTap: (){
          setState(() {
           BlocProvider.of<CommentsBloc>(context).add(Collapse(location: i)); 
          });
        },
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
        color: Theme.of(context).cardColor,
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
  Widget _sortParamsSheet(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: List<Widget>.generate(commentSortTypes.length, (int index) => 
      index == 0
        ? const ActionSheetTitle(title: "Sort")
        : ActionSheetInkwell(
            title: Row(children: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 5.0),
                child: Icon(_getTypeIcon(commentSortTypes[index-1]))
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
IconData _getTypeIcon(String type) {
    switch (type) {
      // * Type sort icons:
      case 'Confidence':
        return MdiIcons.handOkay;
      case 'Top':
        return MdiIcons.trophy;
      case 'New':
        return MdiIcons.newBox;
      case 'Controversial':
        return MdiIcons.swordCross;
      case 'Old':
        return MdiIcons.clock;
      case 'Random':
        return MdiIcons.commentQuestion;
      case 'Q/A':
        return MdiIcons.accountQuestion;
      default:
        //Defaults to best
        return MdiIcons.medal;
    }
  }