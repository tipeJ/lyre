import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/utils/lyre_utils.dart';

class WikiScreen extends StatefulWidget {
  final String pageName;
  final String subreddit;
  final ScrollController controller;
  final String title;

  const WikiScreen({@required this.pageName, @required this.subreddit, this.controller, this.title, Key key}) : super(key: key);

  @override
  _WikiScreenState createState() => _WikiScreenState();
}

class _WikiScreenState extends State<WikiScreen> {

  Future<dynamic> wikiFuture;

  @override
  void initState() { 
    super.initState();
    wikiFuture = PostsProvider().getWikiPage(widget.pageName, widget.subreddit);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? "${widget.subreddit}/wiki/${widget.pageName}"),
      ),
      backgroundColor: Theme.of(context).canvasColor,
      body: FutureBuilder<dynamic>(
        future: wikiFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            if (snapshot.data is WikiPage) {
              return SingleChildScrollView(
                controller: widget.controller,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: MarkdownBody(
                    data: snapshot.data.contentMarkdown,
                    onTapLink: (str) => handleLinkClick(Uri.parse(str), context),
                  )
                ),
              );
            }
            return Center(child: Text(snapshot.data, style: LyreTextStyles.errorMessage));
          }
          return const Center(child: CircularProgressIndicator());
        },
      )
    );
  }
}