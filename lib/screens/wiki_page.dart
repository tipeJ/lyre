import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/utils/lyre_utils.dart';

class WikiScreen extends StatelessWidget {
  final String pageName;
  final String subreddit;
  final ScrollController controller;
  final bool showAppbar;

  const WikiScreen({@required this.pageName, @required this.subreddit, this.controller, this.showAppbar = true, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppbar ? AppBar(
        title: Text("$subreddit/wiki/$pageName"),
      ) : null,
      backgroundColor: showAppbar ? Theme.of(context).canvasColor : Theme.of(context).primaryColor,
      body: FutureBuilder<dynamic>(
        future: PostsProvider().getWikiPage(pageName, subreddit),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            if (snapshot.data is WikiPage) {
              return SingleChildScrollView(
                controller: controller,
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