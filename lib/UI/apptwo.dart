import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/UI/Router.dart';
import 'package:lyre/UI/bottom_appbar.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'package:lyre/UI/media/media_viewer.dart';
import 'package:lyre/UI/reddit_view.dart';

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
      future: getFirstLyreState(),
      builder: (context, AsyncSnapshot<LyreState> snapshot){
        if(snapshot.hasData){
          return BlocProvider(
            builder: (context) => LyreBloc(snapshot.data),
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
    return Container(width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height, color: Colors.red,);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        child: Material(child: Center(child: Text('Lyre', style: TextStyle(fontFamily: 'Roboto', fontSize: 32.0),),),),
        color: Colors.black,
      )
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
            child: 
            /*
            Navigator(
              key: PreviewCall().navigatorKey,
              initialRoute: 'posts',
              onGenerateRoute: Router.generateRoute,
            ),*/
            RedditView(query: "https://old.reddit.com/r/wallpaperdump/comments/dshmke/assorted_backgrounds/f6rmvk8/",) 
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