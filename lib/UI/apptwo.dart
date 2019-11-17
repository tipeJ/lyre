import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/UI/Router.dart';
import 'package:lyre/UI/bottom_appbar.dart';
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
            child: 
            Scaffold(
              body: Container(
                child: PersistentBottomAppbarWrapper(
                  fullSizeHeight: MediaQuery.of(context).size.height,
                  expandingSheetContent: testList(),
                  child: Container(width: MediaQuery.of(context).size.width, height: MediaQuery.of(context).size.height, color: Colors.orange,),
                  appBarContent: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text('appbar'),
                      OutlineButton(
                        child: Text('test button'),
                        onPressed: () {
                          final snackBar = SnackBar(content: Text("Test snackbar"),);
                          Scaffold.of(context).showSnackBar(snackBar);
                        },
                      )
                  ],),
                ),
              ),
            )
            /*
            Navigator(
              key: PreviewCall().navigatorKey,
              initialRoute: 'posts',
              onGenerateRoute: Router.generateRoute,
            ),*/
            //RedditView(query: "https://old.reddit.com/r/AskReddit/comments/dtttsl/you_must_die_in_next_48_hours_if_you_get_a_darwin/f6yqinj/",) 
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
class testList extends State<ExpandingSheetContent> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: ListView.builder(
         controller: widget.innerController,
         physics: widget.scrollEnabled ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
        itemBuilder: (BuildContext context, int index) => Card(child: Center(child: Text(index.toString()),),)
       ),
    );
  }
}