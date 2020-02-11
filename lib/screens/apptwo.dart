import 'package:draw/draw.dart' as draw;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/Router.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/widgets/media/media_viewer.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class App extends StatelessWidget{
  Widget _buildWithTheme(BuildContext context, LyreState themeState){
    return MaterialApp(
      title: 'Lyre',
      theme: themeState.currentTheme.toThemeData,
      home: LyreApp(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: newLyreState(),
      builder: (context, AsyncSnapshot<LyreState> snapshot){
        if(snapshot.hasData){
          return BlocProvider(
            create: (context) => LyreBloc(snapshot.data),
            child: BlocBuilder<LyreBloc, LyreState>(
              builder: _buildWithTheme,
            ),
          );
        } else {
          return MaterialApp(
            home: LyreSplashScreen(),
          );
        }
      },
    );
  }
}
//TODO: Create a splashscreen animation
class LyreSplashScreen extends StatelessWidget {
  const LyreSplashScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Center(child: Material(
        color: Colors.grey[900],
        child: Text('Lyre', style: TextStyle(fontFamily: 'Roboto', fontSize: 32.0, color: Colors.white70, letterSpacing: 3.5,),)
      ),),
      color: Colors.grey[900],
    );
  }
}
class LyreApp extends StatefulWidget {
  @override
  _LyreAppState createState() => _LyreAppState();
}

class _LyreAppState extends State<LyreApp> with PreviewCallback{
  _LyreAppState(){
    PreviewCall().callback = this;
  }

  bool isPreviewing = false;
  var previewUrl = "https://i.imgur.com/n7YQvBx.jpg";

  @override
  void initState(){
    super.initState();
  }

  @override
  void preview(String url) {
    if (!isPreviewing) {
      previewUrl = url;
      showOverlay();
    }
  }

  @override
  void previewEnd() {
    if (isPreviewing && PreviewCall().canPop()) {
      previewUrl = "";
      hideOverlay();
    }
  }

  @override
  void view(String url) {

  }

  showOverlay() {
    if (!isPreviewing) {
      isPreviewing = true;
      setState(() {
        
      });
    }
  }

  hideOverlay() {
    if (isPreviewing) {
      isPreviewing = false;
      setState(() {
        
      });
    }
  }

  @override
  Future<bool> canPop() async {
    if(isPreviewing){
      if (PreviewCall().canPop()){
        previewUrl = "";
        hideOverlay();
      }
      return false;
    }
    return !await PreviewCall().navigatorKey.currentState.maybePop();
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
    builder: (context, constraints) {
      return WillPopScope(
        onWillPop: canPop,
        child: Stack(children: <Widget>[
          IgnorePointer(
            ignoring: isPreviewing,
            child: ChangeNotifierProvider(
              create: (_) => PeekNotifier(),
              child: LyreAdaptiveLayoutBuilder(),
            )
          ),
          Visibility(
            visible: isPreviewing,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              child: MediaViewer(url: previewUrl,),
            ),
          )
        ],)
      );
    },
    );
  }
}

class LyreAdaptiveLayoutBuilder extends StatefulWidget {
  LyreAdaptiveLayoutBuilder({Key key}) : super(key: key);

  @override
  LyreAdaptiveLayoutBuilderState createState() => LyreAdaptiveLayoutBuilderState();
}

class LyreAdaptiveLayoutBuilderState extends State<LyreAdaptiveLayoutBuilder> {

  static const double _peekDividerWidth = 3.5;

  static const double _peekWindowDefaultWidth = 400;
  double _peekWindowWidth = _peekWindowDefaultWidth;
  bool _peekVisible = false;

  static const double _peekHandleWidth = 35.0;
  static const double _peekHandleHeight = 50.0;

  @override
  void dispose() { 
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Navigator(
                key: PreviewCall().navigatorKey,
                initialRoute: 'posts',
                onGenerateRoute: Router.generateRoute,
              ),
            ),
            Consumer<PeekNotifier>(
              builder: (context, peekContent, child) => peekContent.route == null
                ? const SizedBox()
                : Row(
                    children: [
                      Container(
                        child: Container(
                          width: _peekDividerWidth,
                          height: MediaQuery.of(context).size.height,
                          color: Theme.of(context).canvasColor
                        )
                      ),
                      Container(
                        width: _peekWindowWidth,
                        color: Theme.of(context).canvasColor,
                        child: _peekContent(peekContent)
                      )
                    ]
                  )
            ),
          ],
        ),
        Consumer<PeekNotifier>(
          builder: (context, peekContent, child) => peekContent.route == null
            ? const SizedBox()
            : Positioned(
                top: MediaQuery.of(context).size.height / 2 - _peekHandleHeight / 2,
                right: (_peekWindowWidth - _peekHandleWidth / 2) + _peekDividerWidth / 2,
                child: _PeekResizeSlider(onDragUpdate: (dx){
                  setState(() {
                    _peekWindowWidth+=-dx;
                  });
                }),
              ),
        )
      ]
    );
  }
  Widget _peekContent(PeekNotifier peekContent) {
    draw.UserContent content = peekContent.args;
    if (content is draw.Submission) {
      if(recentlyViewed.contains(content)) recentlyViewed.remove(content); //removes the submission from the list (will be readded, to index 0)
      recentlyViewed.add(content); //Adds the submission to the top of the recently viewed list
    }
    return BlocProvider(
      create: (context) => CommentsBloc(content),
      child: CommentList(),
    );
  }
}

class _PeekResizeSlider extends StatefulWidget {
  final Function(double dx) onDragUpdate;
  const _PeekResizeSlider({this.onDragUpdate, Key key}) : super(key: key);

  @override
  __PeekResizeSliderState createState() => __PeekResizeSliderState();
}

class __PeekResizeSliderState extends State<_PeekResizeSlider> {

  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AnimatedContainer(
        curve: Curves.ease,
        duration: const Duration(milliseconds: 200),
        width: 35.0,
        height: 50.0,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(color: Theme.of(context).canvasColor, width: 2.5),
          borderRadius: BorderRadius.circular(_focused ? 10.0 : 20.0)
        ),
        child: const Icon(MdiIcons.dotsVertical),
      ),
      onHorizontalDragStart: (details) {
        setState(() {
          _focused = true;
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          _focused = false;
        });
      },
      onHorizontalDragUpdate: (details) => widget.onDragUpdate(details.delta.dx),
      onDoubleTap: () => Provider.of<PeekNotifier>(context).disable(),
    );
  }
}

class PeekNotifier with ChangeNotifier {
  String route;
  dynamic args;

  void changePeek(String route, dynamic args) {
    this.route = route;
    this.args = args;
    notifyListeners();
  }
  
  void disable() {
    route = null;
    args = null;
    notifyListeners();
  }
}