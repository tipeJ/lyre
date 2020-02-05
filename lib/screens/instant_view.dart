import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:lyre/utils/utils.dart';

class InstantViewScreen extends StatefulWidget {
  final Uri initialUri;

  const InstantViewScreen({Key key, @required this.initialUri});

  @override
  _InstantViewScreenState createState() => _InstantViewScreenState();
}

class _InstantViewScreenState extends State<InstantViewScreen> with SingleTickerProviderStateMixin{
  AnimationController _fadeAnimation;
  ScrollController _controller;

  @override
  void initState() { 
    super.initState();
    _fadeAnimation = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _controller = ScrollController();
  }

  @override
  void dispose() { 
    _fadeAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Response>(
      future: PostsProvider().client.get(widget.initialUri),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          _fadeAnimation.animateTo(1.0, curve: Curves.ease);
          // final parsedHtml = parse(snapshot.data.body);
          // final elements = parsedHtml.children.where((e) => e.nodeType == );
          // final elements = parsedHtml.querySelectorAll("h1, h2, h3, h4, h5, h6, p");
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(10.0),
                controller: _controller,
                child: Html(
                  data: snapshot.data.body,
                  onLinkTap: (str) => handleLinkClick(Uri.parse(str), context),
                ),
              )
              // body: ListView.builder(
              //   padding: const EdgeInsets.all(10.0),
              //   controller: _controller,
              //   itemCount: elements.length,
              //   itemBuilder: (context, i) {
              //     final e = elements[i];
              //     return Text(
              //       e.text,
              //       style: _headers.contains(e.localName)
              //         ? Theme.of(context).textTheme.title.apply(
              //             fontSizeFactor: 1 - (_headers.indexOf(e.localName) / 10)
              //           )
              //         : Theme.of(context).textTheme.body1.apply(color: Theme.of(context).textTheme.body2.color)
              //     );
              //   }
              // )
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
  static const List<String> _headers = ["h1", "h2", "h3", "h4", "h5", "h6"];
}