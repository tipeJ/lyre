import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:html/parser.dart' show parse;
class InstantViewScreen extends StatefulWidget {
  final Uri initialUri;

  const InstantViewScreen({Key key, @required this.initialUri});

  @override
  _InstantViewScreenState createState() => _InstantViewScreenState();
}

class _InstantViewScreenState extends State<InstantViewScreen> with SingleTickerProviderStateMixin{
  AnimationController _fadeAnimation;
  ScrollController _controller;

  Future<dynamic> _bodyResponse;

  @override
  void initState() { 
    super.initState();
    _fadeAnimation = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _controller = ScrollController();
    
    _bodyResponse = _getBodyResponse();
  }

  @override
  void dispose() { 
    _fadeAnimation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.text_format),
        onPressed: () {
          setState(() {
            
          });
        },
      ),
      body: FutureBuilder(
        future: _bodyResponse,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            _fadeAnimation.animateTo(1.0, curve: Curves.ease);
            final elements = snapshot.data.querySelectorAll("h1, h2, h3, h4, h5, h6, p");
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ListView.separated(
                padding: const EdgeInsets.all(10.0),
                controller: _controller,
                itemCount: elements.length,
                separatorBuilder: (context, i) => _headers.contains(elements[i].localName) ? const SizedBox(height: 25.0) : const SizedBox(height: 15.0),
                itemBuilder: (context, i) {
                  final e = elements[i];
                  return Text(
                    e.text,
                    style: _headers.contains(e.localName)
                      ? Theme.of(context).textTheme.title.apply(
                          fontSizeFactor: 1 - (_headers.indexOf(e.localName) / 10)
                        )
                      : Theme.of(context).textTheme.body1
                  );
                }
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      )
    );
  }
  Future<dynamic> _getBodyResponse() async {
    final response = await PostsProvider().client.get(widget.initialUri);
    return compute(parse, response.body);
  }
  static const List<String> _headers = ["h1", "h2", "h3", "h4", "h5", "h6"];
}