import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:html/parser.dart' show parse;
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:provider/provider.dart';
class InstantViewScreen extends StatefulWidget {
  final Uri initialUri;

  const InstantViewScreen({Key key, @required this.initialUri});

  @override
  _InstantViewScreenState createState() => _InstantViewScreenState();
}

class InstantViewProvider extends ChangeNotifier {

  String textSizeTitle = _fontSizesMap.keys.elementAt(3);
  double get textSize => _fontSizesMap[textSizeTitle];

  bool selectionEnabled = false;

  void setTextSize(String newSize) {
    textSizeTitle = newSize;
    notifyListeners();
  }

  void toggleSelectionEnabled() {
    selectionEnabled = !selectionEnabled;
    notifyListeners();
  }
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
      floatingActionButton: _InstantViewFAB(),
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
                  return Consumer<InstantViewProvider>(
                    builder: (_, provider, child) {
                      final style = _headers.contains(e.localName)
                        ? Theme.of(context).textTheme.title.apply(
                            fontSizeFactor: (1 - (_headers.indexOf(e.localName) / 15)) * provider.textSize
                          )
                        : Theme.of(context).textTheme.body1.apply(fontSizeFactor: provider.textSize);
                      if (provider.selectionEnabled) return SelectableText(e.text, style: style);
                      return Text(e.text, style: style);
                    }
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

class _InstantViewFAB extends StatefulWidget {
  final Function(double) changeTextSize;
  const _InstantViewFAB({this.changeTextSize, Key key}) : super(key: key);

  @override
  __InstantViewFABState createState() => __InstantViewFABState();
}

class __InstantViewFABState extends State<_InstantViewFAB> with SingleTickerProviderStateMixin {

  AnimationController _expansionController;

  @override
  void initState() {
    _expansionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _expansionController.addListener((){setState(() {});});
    super.initState();
  }

  @override
  void dispose() { 
    _expansionController.dispose();
    super.dispose();
  }

  double _lerp(double min, double max) => lerpDouble(min, max, _expansionController.value);

  void _toggleExpansion() {
    if (_expansionController.value > 0.7) {
      _expansionController.animateBack(0.0, curve: Curves.ease);
    } else {
      _expansionController.animateTo(1.0, curve: Curves.ease);
    }
  }

  Future<bool> _willPop() {
    if (_expansionController.value > 0.5) {
      _expansionController.animateBack(0.0, curve: Curves.ease);
      return Future.value(false);
    }
    return Future.value(true);
  }

  static const int _numChildren = 2;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPop,
      child: Material(
        borderRadius: BorderRadius.circular(_lerp(25.0, BlocProvider.of<LyreBloc>(context).state.currentTheme.borderRadius.toDouble())),
        clipBehavior: Clip.antiAlias,
        color: Color.lerp(Theme.of(context).accentColor, Theme.of(context).primaryColor, _expansionController.value),
        child: Container(
          width: _lerp(50.0, 125),
          height: _lerp(50, _numChildren * 60 + 40.0),
          child: Stack(
            children: <Widget>[
              IgnorePointer(
                ignoring: _expansionController.value < 0.5,
                child: Opacity(
                  opacity: _lerp(0.0, 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          child: Container(
                            width: 40.0,
                            height: 40.0,
                            child: const Icon(Icons.close)
                          ),
                          onTap: _toggleExpansion,
                        )
                      ),
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(5.0),
                          height: 50.0,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Text Size",
                                style: Theme.of(context).primaryTextTheme.body1.apply(color: Theme.of(context).primaryTextTheme.body1.color),
                              ),
                              Text(
                                Provider.of<InstantViewProvider>(context).textSizeTitle,
                                style: Theme.of(context).primaryTextTheme.body2,
                              )
                            ],
                          ),
                        ),
                        onTap: () {
                          Scaffold.of(context).showBottomSheet((_) => Container(
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List<ListTile>.generate(_fontSizesMap.length, (i) => ListTile(
                                title: Text(
                                  _fontSizesMap.keys.elementAt(i).toString(),
                                  style: TextStyle(fontWeight: _fontSizesMap.values.elementAt(i) == Provider.of<InstantViewProvider>(context).textSize ? FontWeight.bold : FontWeight.normal),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Provider.of<InstantViewProvider>(context).setTextSize(_fontSizesMap.keys.elementAt(i));
                                },
                              )),
                            )
                          ));
                        },
                      ),
                      InkWell(
                        child: Container(
                          padding: const EdgeInsets.all(5.0),
                          height: 50.0,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: InkWell(
                                  child: const Text("Enable Selection"),
                                ),
                              ),
                              Consumer<InstantViewProvider>(
                                builder: (_, provider, child) => Checkbox(
                                  value: provider.selectionEnabled,
                                  onChanged: (b) => provider.toggleSelectionEnabled(),
                                ),
                              )
                            ],
                          ),
                        ),
                        onTap: () => Provider.of<InstantViewProvider>(context).toggleSelectionEnabled(),
                      ),
                  ])
                )
              ),
              IgnorePointer(
                ignoring: _expansionController.value > 0.5,
                child: Opacity(
                  opacity: _lerp(1.0, 0.0),
                  child: InkWell(
                    customBorder: CircleBorder(),
                    onTap: _toggleExpansion,
                    child: const Center(child: Icon(Icons.text_format))
                  ),
                )
              )
            ],
          ),
        )
      )
    );
  }
}

const Map<String, double> _fontSizesMap = {
  "Tiny" : 0.6,
  "Very Small" : 0.75,
  "Small" : 0.9,
  "Normal" : 1.0,
  "Large" : 1.1,
  "Very Large" : 1.25,
  "Huge" : 2.0,
};