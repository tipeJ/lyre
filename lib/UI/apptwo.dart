import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/UI/Router.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'package:lyre/UI/media/media_viewer.dart';

class App extends StatelessWidget{
  Widget _buildWithTheme(BuildContext context, LyreState themeState){
    return MaterialApp(
      title: 'Lyre',
      theme: themeState.themeData,
      home: LyreApp(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox('settings'),
      builder: (context, AsyncSnapshot<Box> snapshot){
        if(snapshot.hasData){
          final prefs = snapshot.data;
          final initialTheme = prefs.get(CURRENT_THEME) ?? "";
          var _cTheme = LyreTheme.DarkTeal;
          LyreTheme.values.forEach((theme){
            if(theme.toString() == initialTheme){
              _cTheme = theme;
            }
          });
          return BlocProvider(
            builder: (context) => LyreBloc(LyreState(
              themeData: lyreThemeData[_cTheme],
              settings: prefs
            )),
            child: BlocBuilder<LyreBloc, LyreState>(
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
    if (isPreviewing) {
      previewUrl = "";
      hideOverlay();
    }
  }

  @override
  void view(String url) {}

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
  void dispose() {
    super.dispose();
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
            child: Navigator(
              key: PreviewCall().navigatorKey,
              initialRoute: 'posts',
              onGenerateRoute: Router.generateRoute,
            ), 
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