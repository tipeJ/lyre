import 'package:flutter/material.dart';
import 'package:draw/draw.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/textstyles.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:lyre/widgets/comment.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/widgets/postInnerWidget.dart';
import 'package:lyre/widgets/widgets.dart';
import '../Resources/RedditHandler.dart';
import '../Resources/globals.dart';

class replyWindow extends StatefulWidget {
  final UserContent content;
  final String initialText;
  replyWindow(this.content, [this.initialText]);

  _replyWindowState createState() => _replyWindowState();
}

class _replyWindowState extends State<replyWindow> with SingleTickerProviderStateMixin {
  
  TextEditingController _replyController;
  TabController _replyTabController;
  ScrollController _scrollController;

  _replyWindowState();

  SendingState _replySendingState = SendingState.Inactive;
  String titleText = "Reply to u/";
  String error = "";

  bool popReady = true;
  Future<bool> _willPop(){
    if (_replySendingState == SendingState.Error) {
      setState(() {
       _replySendingState = SendingState.Inactive; 
      });
      return Future.value(false);
    } else if (_replySendingState == SendingState.Sending){
      return Future.value(false);
    }
    return popReady ? Future.value(true) : Future.value(false);
  }
  List<Widget> parentWidgets = [];

  final double initialHeight = 250;

  @override
  void initState() {
    _replyController = TextEditingController(text: widget.initialText ?? "");
    _replyController.addListener(() {
      setState((){});
    });
    _replyTabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    titleText += widget.content is Submission ? (widget.content as Submission).author : (widget.content as Comment).author;
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
         onWillPop: _willPop,
         child: Scaffold(
           resizeToAvoidBottomInset: true,
           body: Stack(
             children: <Widget>[
              IgnorePointer(
                ignoring: _replySendingState != SendingState.Inactive,
                child: BlocBuilder<LyreBloc, LyreState>(
                  builder: (context, state) {
                    return NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (context, b) {
                        return [
                          SliverAppBar(
                            title: Text(titleText),
                            actions: <Widget>[
                              IconButton(
                                icon: Icon(Icons.send),
                                onPressed: _reply,
                              )
                            ]
                          ),
                          SliverList(delegate: SliverChildListDelegate([
                            widget.content is Comment
                              ? CommentContent(widget.content, PreviewSource.PostsList)
                              : postInnerWidget(
                                  submission: widget.content as Submission,
                                  previewSource: PreviewSource.Comments,
                                  linkType: getLinkType((widget.content as Submission).url.toString()),
                                  fullSizePreviews: state.fullSizePreviews,
                                  showCircle: state.showPreviewCircle,
                                  blurLevel: state.blurLevel.toDouble(),
                                  showNsfw: state.showNSFWPreviews,
                                  showSpoiler: state.showSpoilerPreviews,
                                  onOptionsClick: () {},
                                ),
                            TabBar(
                              indicatorColor: Colors.transparent,
                              controller: _replyTabController,
                              tabs: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text('Edit')
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text('Preview')
                                ),
                              ],
                            ),
                          ]),)
                        ];
                      },
                      body: TabBarView(
                        controller: _replyTabController,
                        children: <Widget>[
                          TextField(
                            enabled: _replySendingState == SendingState.Inactive,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            controller: _replyController,
                            decoration: const InputDecoration(
                              hintText: "Your Text Here",
                              contentPadding: EdgeInsets.symmetric(horizontal: 5.0)
                            ),
                          ),
                          _replyController.text.isNotEmpty 
                            ? Padding(
                              padding: EdgeInsets.all(10.0),
                              child: MarkdownBody(
                                data: _replyController.text,
                                styleSheet: LyreTextStyles.getMarkdownStyleSheet(context)
                              ) 
                            )
                            : const Center(child: Text("Markdown is Cool!"),)
                        ],
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 0.0,
                child: Material(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: Theme.of(context).primaryColor,
                    child: InputOptions(controller: _replyController,)
                  )
                ),
              ),
              prefix0.Visibility (
                visible: _replySendingState != SendingState.Inactive,
                child: Container (
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  color: Colors.black.withOpacity(0.6),
                  child: _replySendingState == SendingState.Sending
                      ? Center(
                        child: CircularProgressIndicator()
                      )
                      : Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.0),
                            child: Text('ERROR: ' + error, style: LyreTextStyles.errorMessage,),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                            OutlineButton(
                              child: Text('Close'),
                              onPressed:() => Navigator.of(context).maybePop(),
                            ),
                            OutlineButton(
                              child: Text('Retry'),
                              onPressed: _reply,
                            )
                          ],)
                        ],
                      )
                )
              )
             ],
           ),
         ),
       );
  }

  ///Submit your [Comment] reply.
  _reply() {
    setState(() {
      _replySendingState = SendingState.Sending;
    });
    reply(widget.content, _replyController.text).then((value) {
      if (value is String) {
        setState(() {
          error = value;
          _replySendingState = SendingState.Error;
        });
      } else if (value is Comment) {
        print('poping');
        Navigator.of(context).pop(value);
      }
    });
  }
}