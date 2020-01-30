import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';
import 'package:html/parser.dart';

import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/utils/utils.dart';

const _redditHelpUrl = "https://www.reddithelp.com";

class RedditHelpScreen extends StatefulWidget {
  const RedditHelpScreen({Key key}) : super(key: key);

  @override
  _RedditHelpScreenState createState() => _RedditHelpScreenState();
}

class _RedditHelpScreenState extends State<RedditHelpScreen> {

  Future<Response> _responseFuture;

  @override
  void initState() { 
    super.initState();
    _responseFuture = PostsProvider().client.get("https://www.reddithelp.com/en");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: "Open in Browser",
            onPressed: () => launchURL(context, "https://www.reddithelp.com/en"),
          )
        ],
      ),
      body: FutureBuilder<Response>(
        future: _responseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            final response = snapshot.data;
            final data = parse(response.body);
            final grid = data.getElementsByClassName("primary-grid").first;
            final topics = grid.getElementsByClassName("block topic-list");
            return ListView.builder(
              itemCount: topics.length,
              itemBuilder: (context, i) {
                final element = topics[i];
                final title = element.getElementsByClassName("block-title").first;
                final content = element.getElementsByClassName("block-content").first;
                final topicChildren =content.getElementsByClassName("link-list--item");
                return Column(children: <Widget>[
                  ExpansionTile(
                    leading: CircleAvatar(
                      backgroundImage: AdvancedNetworkImage(title.getElementsByTagName("img").first.attributes["src"]),
                    ),
                    title: AutoSizeText(
                      title.children.last.innerHtml.replaceAll("amp;", ""), 
                      style: Theme.of(context).textTheme.display3,
                      maxFontSize: 26.0,
                    ),
                    children: List<ListTile>.generate(topicChildren.length, (i) {
                      final listItem = topicChildren[i];
                      final isCategory = i == topicChildren.length - 1;
                      return ListTile(
                        title: Text(listItem.text.trim()),
                        trailing: isCategory ? const Icon(Icons.navigate_next) : null,
                        onTap: () {
                          Navigator.of(context).push(CupertinoPageRoute(builder: (_) => _RedditHelpTopic(
                            title: isCategory ? title.children.last.innerHtml.replaceAll("amp;", "") : listItem.text,
                            url: "$_redditHelpUrl${listItem.firstChild.attributes["href"]}",
                            helpType: isCategory ? _RedditHelpPage.Category : _RedditHelpPage.Topic,
                          )));
                        },
                      );
                    }),
                  )
                ],);
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

enum _RedditHelpPage {
  Topic,
  Category
}

class _RedditHelpTopic extends StatefulWidget {
  final String url;
  final String title;
  final _RedditHelpPage helpType;

  const _RedditHelpTopic({@required this.url, @required this.title, @required this.helpType, Key key}) : super(key: key);

  @override
  State createState() => helpType == _RedditHelpPage.Topic ? _RedditHelpTopicState() : _RedditHelpCategoryState();
}

class _RedditHelpCategoryState extends State<_RedditHelpTopic> {
  
  Future<Response> content;

  @override
  void initState() { 
    super.initState();
    content = PostsProvider().client.get(widget.url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title.trim()),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.open_in_browser),
          tooltip: "Open in Browser",
          onPressed: () => launchURL(context, widget.url),
        )
      ],
    ),
    body: FutureBuilder<Response>(
      future: content,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final grid = parse(snapshot.data.body).getElementsByClassName("smart-grid").first.children;
          return ListView.builder(
            itemCount: grid.length,
            itemBuilder: (context, i) {
              final item = grid[i];
              final title = grid[i].getElementsByClassName("block-title").first;
              final children = item.getElementsByClassName("link-list--link");
              return ExpansionTile(
                title: Text(title.text),
                children: List<ListTile>.generate(children.length, (i) {
                  final topic = children[i];
                  return ListTile(
                    title: Text(topic.getElementsByTagName("span").first.text),
                    onTap: () {
                      Navigator.of(context).push(CupertinoPageRoute(builder: (_) => _RedditHelpTopic(
                        url: "https://www.reddithelp.com${topic.attributes['href']}",
                        title: topic.getElementsByTagName("span").first.text,
                        helpType: _RedditHelpPage.Topic,
                      )));
                    },
                  );
                }),
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    ),
  );
}

class _RedditHelpTopicState extends State<_RedditHelpTopic> {
  
  Future<Response> content;

  @override
  void initState() { 
    super.initState();
    content = PostsProvider().client.get(widget.url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title.trim()),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.open_in_browser),
          tooltip: "Open in Browser",
          onPressed: () => launchURL(context, widget.url),
        )
      ],
    ),
    body: FutureBuilder<Response>(
      future: content,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          final data = parse(snapshot.data.body).getElementsByClassName("article--devices single-device").first;
          return SingleChildScrollView(
            child: Html (
              onLinkTap: (str) => handleLinkClick(Uri.parse(str), context),
              padding: const EdgeInsets.all(10.0),
              data: data.innerHtml,
            )
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    ),
  );
}