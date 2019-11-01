import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/UI/Router.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'package:lyre/UI/media/media_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatelessWidget{
  Widget _buildWithTheme(BuildContext context, ThemeState themeState){
    return MaterialApp(
      title: 'Lyre',
      theme: themeState.themeData,
      home: LyreApp(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, AsyncSnapshot<SharedPreferences> snapshot){
        if(snapshot.hasData){
          final prefs = snapshot.data;
          return BlocProvider(
            builder: (context) => ThemeBloc(prefs.get('currentTheme') == null ? "" : prefs.get('currentTheme')),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: _buildWithTheme,
            ),
          );
        }else{
          return Container(
            width: 25.0,
            height: 25.0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
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

  OverlayEntry _overlayEntry;
  bool isPreviewing = false;
  OverlayState overlayState;
  var previewUrl = "https://i.imgur.com/CSS40QN.jpg";

  @override
  void initState(){
    overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(builder: (context) => Container(
      color: Colors.black.withOpacity(0.8),
      child: MediaViewer(url: previewUrl),
    ));
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
    if (isPreviewing) {
      previewUrl = "";
      // previewController.reverse();
      hideOverlay();
    }
  }

  @override
  void view(String url) {}

  showOverlay() {
    if (!isPreviewing) {
      overlayState.insert(_overlayEntry);
      isPreviewing = true;
    }
  }

  hideOverlay() {
    if (isPreviewing) {
      _overlayEntry.remove();
      overlayState.deactivate();
      isPreviewing = false;
    }
  }

  @override
  Future<bool> canPop() async {
    if(isPreviewing){
      if (!PreviewCall().canPop()){
        previewUrl = "";
        hideOverlay();
      }
      return false;
    }
    return !await PreviewCall().navigatorKey.currentState.maybePop();
  }

  @override
  void dispose() {
    overlayState.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
    builder: (context, constraints) {
      return WillPopScope(
        onWillPop: canPop,
        child: Navigator(
          key: PreviewCall().navigatorKey,
          initialRoute: 'posts',
          onGenerateRoute: Router.generateRoute,
        ),
      );
    },
    );
  }
}