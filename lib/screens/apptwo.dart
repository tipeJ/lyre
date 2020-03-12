import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/Router.dart';
import 'package:lyre/screens/interfaces/previewCallback.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/utils/lyre_utils.dart';
import 'package:lyre/utils/utils.dart';
import 'package:lyre/widgets/media/media_preview.dart';
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
        child: const Text('Lyre', style: TextStyle(fontFamily: 'Roboto', fontSize: 32.0, color: Colors.white70, letterSpacing: 3.5))
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
  void previewEnd() async {
    if (isPreviewing && await PreviewCall().canPop()) {
      previewUrl = "";
      hideOverlay();
    }
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
      if (await PreviewCall().canPop()){
        previewUrl = "";
        hideOverlay();
      }
      return false;
    }
    return !await PreviewCall().navigatorKey.currentState.maybePop();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: canPop,
      child: Stack(children: <Widget>[
        IgnorePointer(
          ignoring: isPreviewing,
          child: ChangeNotifierProvider(
            create: (_) => PeekNotifier(),
            child: LyreSplitScreen()
          )
        ),
        Visibility(
          visible: isPreviewing,
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: MediaPreview(url: previewUrl)
          )
        )
      ])
    );
  }
}

class LyreSplitScreen extends StatefulWidget {

  LyreSplitScreen({Key key}) : super(key: key);

  @override
  LyreSplitScreenState createState() => LyreSplitScreenState();
}

class LyreSplitScreenState extends State<LyreSplitScreen> {
  /// If this limit is crossed, the peek window will be dismissed.
  static const double _peekWindowMinWidth = 200;
  /// The default peek window width. Will be reverted to this after every dismiss.
  static const double _peekWindowDefaultWidth = 400;
  double _peekWindowWidth = _peekWindowDefaultWidth;

  /// The default vertical position for the handle.
  double _peekHandleVerticalPosition = 500.0;

  @override
  void dispose() { 
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (!wideLayout(size: MediaQuery.of(context).size)) return _mainNavigator;
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child: _mainNavigator),
            Consumer<PeekNotifier>(
              builder: (context, peekContent, child) {
                if (peekContent.route == null) _peekWindowWidth = _peekWindowDefaultWidth;
                return peekContent.route == null
                  ? const SizedBox()
                  : Row(
                      children: [
                        Container(
                          child: Container(
                            width: screenSplitterWidth,
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
              );
            }
            )
          ]
        ),
        Consumer<PeekNotifier>(
          builder: (context, peekContent, child) => peekContent.route == null
            ? const SizedBox()
            : Positioned(
                top: _peekHandleVerticalPosition - _peekHandleHeight / 2,
                right: (_peekWindowWidth - _peekHandleWidth / 2) + screenSplitterWidth / 2,
                child: _PeekResizeSlider(
                  onHorizontalDragUpdate: (dx){
                    setState(() {
                      double newHorizontalPosition = _peekWindowWidth+-dx;
                      if (newHorizontalPosition < _peekWindowMinWidth) {
                        Provider.of<PeekNotifier>(context).disable();
                      } else if (newHorizontalPosition < MediaQuery.of(context).size.width * 0.8) {
                        _peekWindowWidth = newHorizontalPosition;
                      } 
                    });
                  },
                  onVerticalDragUpdate: (dy){
                    setState(() {
                      double newVerticalPosition = _peekHandleVerticalPosition + dy;
                      if (newVerticalPosition < MediaQuery.of(context).size.height * 0.8 && newVerticalPosition > MediaQuery.of(context).size.height * 0.2) {
                        _peekHandleVerticalPosition = newVerticalPosition;
                      }
                    });
                  },
                )
              )
        )
      ]
    );
  }

  static Widget  get _mainNavigator => Navigator(
    key: PreviewCall().navigatorKey,
    initialRoute: 'posts',
    onGenerateRoute: Router.generateRoute,
  );

  static Widget _peekContent(PeekNotifier peekContent) {
    return Router.generateWidget(peekContent.route, peekContent.args, peekContent.key.toString());
  }
}

const double _peekHandleWidth = 35.0;
const double _peekHandleHeight = 50.0;

class _PeekResizeSlider extends StatefulWidget {
  final Function(double dx) onHorizontalDragUpdate;
  final Function(double dy) onVerticalDragUpdate;
  const _PeekResizeSlider({this.onHorizontalDragUpdate, this.onVerticalDragUpdate, Key key}) : super(key: key);

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
        width: _peekHandleWidth,
        height: _peekHandleHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          border: Border.all(color: _focused ? Theme.of(context).highlightColor : Theme.of(context).canvasColor, width: 2.5),
          borderRadius: BorderRadius.circular(_focused ? 10.0 : 20.0)
        ),
        child: const Icon(MdiIcons.dotsVertical),
      ),
      onTapDown: (details) {
        setState(() {
          _focused = true;
        });
      },
      onTapUp: (details) => _dismiss(),
      onHorizontalDragEnd: (details)  => _dismiss(),
      onVerticalDragEnd: (details)  => _dismiss(),
      onHorizontalDragUpdate: (details) => widget.onHorizontalDragUpdate(details.delta.dx),
      onVerticalDragUpdate: (details) => widget.onVerticalDragUpdate(details.delta.dy),
      onDoubleTap: () => Provider.of<PeekNotifier>(context).disable(),
    );
  }
  void _dismiss() {
    setState((){
      _focused = false;
    });
  }
}
class PeekNotifier with ChangeNotifier {
  // TODO: Fix this purkka fix
  int key = 0;
  String route;
  dynamic args;

  void changePeek(String route, dynamic args) {
    key = key == 0 ? 1 : 0;
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