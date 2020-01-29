import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/utils/utils.dart';

class RulesScreen extends StatelessWidget {
  final String subreddit;
  final BuildContext parentContext;
  const RulesScreen({@required this.subreddit, this.parentContext, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: PostsProvider().getSubredditRules(subreddit),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          if (snapshot.data is String) {
            return Center(child: Text(snapshot.data, style: LyreTextStyles.errorMessage));
          } else {
            final rules = snapshot.data as List<Rule>;
            return Column(
              children: [
                Material(
                  color: Theme.of(context).primaryColor,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    width: MediaQuery.of(context).size.width,
                    child: Text("Rules", style: Theme.of(context).primaryTextTheme.title)
                  )
                ),
                Material(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height/1.75,
                    child: ListView.builder(
                      itemCount: rules.length,
                      itemBuilder: (context, i) => ExpansionTile(
                        title: Text(rules[i].shortName),
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: MarkdownBody(
                              onTapLink: (str) {
                                Navigator.of(context).pop();
                                handleLinkClick(Uri.parse(str), parentContext);
                              },
                              data: rules[i].description
                            )
                          )
                        ],
                      ),
                    )
                  )
                )
              ]
            );
          }
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}