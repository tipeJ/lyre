import 'package:flutter/material.dart';
import '../Models/item_model.dart';
import '../Blocs/posts_bloc.dart';
import '../Resources/globals.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../Models/Comment.dart';
import '../Ui/Animations/slide_right_transition.dart';
import 'comments_list.dart';
import 'package:swipedetector/swipedetector.dart';
import 'apptwo.dart';

class lyApp extends StatefulWidget{
  PostsList createState() => new PostsList();
}
class PostsList extends State<lyApp> with SingleTickerProviderStateMixin {
  var titletext = "Lyre for Reddit";
  var currentSub = "";

  Tween heightTween = new Tween<double>(begin: 0.0, end: 0.0);
  Tween height2Tween = new Tween<double>(begin: 0.0, end: 350.0);
  Tween padTween = new Tween<double>(begin: 25.0, end: 0.0);
  Tween roundTween = new Tween<double>(begin: 10.0, end: 0.0);
  Tween edgeTween = new Tween<double>(begin: 20.0, end: 0.0);
  AnimationController controller;
  Animation<double> heightAnimation;
  Animation<double> height2Animation;
  Animation<double> padAnimation;
  Animation<double> roundAnimation;
  Animation<double> edgeAnimation;

  bool isElevated = false;


  void reverse(BuildContext context){
    heightAnimation = heightTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeInSine));
    padAnimation = padTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeOutSine));
    roundAnimation = roundTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeOutSine));
    edgeAnimation = edgeTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeOutSine));
    height2Animation = height2Tween.animate(CurvedAnimation(parent: controller, curve: Curves.easeOutSine));
    controller.reset();
    controller.reverse();
    isElevated = false;
  }
  void initV(BuildContext context){
    heightTween.begin = 50.0;
    heightTween.end = 400.0;

    heightAnimation = heightTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeOutSine));
    padAnimation = padTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeInSine));
    roundAnimation = roundTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeInSine));
    edgeAnimation = edgeTween.animate(CurvedAnimation(parent: controller, curve: Curves.easeInSine));
    height2Animation = height2Tween.animate(CurvedAnimation(parent: controller, curve: Curves.easeInSine));
    heightAnimation.addListener(() {
      setState(() {
      });
    });
    height2Animation.addListener((){
      setState(() {
      });
    });
    padAnimation.addListener((){
      setState(() {
      });
    });
    edgeAnimation.addListener(() {
      setState(() {
      });
    });
    roundAnimation.addListener((){
      setState(() {
      });
    });
    controller.reset();
  }
  @override
  void initState() {
    super.initState();

    new Future.delayed(Duration.zero, (){
      initV(context);
    });
    controller = new AnimationController(vsync: this,
        duration: new Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context) {
    bloc.fetchAllPosts();
    return Scaffold(
      drawer: new Drawer(
          child: new ListView.builder(
              padding: new EdgeInsets.all(16.0),
              itemCount: subreddits.length,
              itemExtent: 50.0,
              itemBuilder: (BuildContext context, int i) {
                return new ListTile(
                    leading: const Icon(Icons.arrow_right),
                    title: new Text(subreddits[i],
                        textScaleFactor: 1.0,
                        style: DefaultTextStyle.of(context)
                            .style
                            .apply(fontSizeFactor: 1.5)),
                    onTap: () {
                      currentSubreddit = subreddits[i];
                      bloc.fetchAllPosts();
                    });
              })),
      body: new Container(
        child: new Stack(
          children: <Widget>[
            new StreamBuilder(
              stream: bloc.allPosts,
              builder: (context, AsyncSnapshot<ItemModel> snapshot) {
                if (snapshot.hasData) {
                  return buildList(snapshot);
                } else if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }
                return Center(child: CircularProgressIndicator());
              },
            ),
            new Container(
              alignment: Alignment.bottomCenter,
              padding: new EdgeInsets.only(
                  bottom: padAnimation.value,
                  right: edgeAnimation.value,
                  left: edgeAnimation.value),

              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  new AnimatedContainer(
                    child: new Card(
                          color: Color.fromARGB(255, 70, 64, 66),
                          elevation: 4.0,
                          shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(roundAnimation.value)
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: <Widget>[
                              new GestureDetector(
                                  onVerticalDragUpdate: (DragUpdateDetails details){
                                    if(details.delta.direction < 1.0 && !isElevated){
                                      initV(context);
                                      controller.forward();
                                      isElevated = true;
                                    }else if(details.delta.direction > 1.0 && isElevated){
                                      reverse(context);
                                    }
                                  },
                                child: new Container(
                                  child: new Text(
                                    currentSubreddit,
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 35.0,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  width: MediaQuery.of(context).size.width,
                                )

                              ),
                              new Container(
                                height: height2Animation.value,
                                child: new ListView.builder(
                                    padding: new EdgeInsets.all(16.0),
                                    itemCount: subreddits.length,
                                    itemExtent: 50.0,
                                    itemBuilder: (BuildContext context, int i) {
                                      return new ListTile(
                                          leading: const Icon(Icons.arrow_right),
                                          title: new Text(subreddits[i],
                                              textScaleFactor: 1.0,
                                              style: DefaultTextStyle.of(context)
                                                  .style
                                                  .apply(fontSizeFactor: 1.5)),
                                          onTap: () {
                                            currentSubreddit = subreddits[i];
                                            reverse(context);
                                            bloc.fetchAllPosts();
                                            scontrol.animateTo(0.0, duration: Duration(milliseconds: 400), curve: Curves.decelerate);
                                          });
                                    }),
                              ),
                            ],

                          ),
                        ),
                  duration: Duration(milliseconds: 350),
                  height: heightAnimation.value,
                  width: MediaQuery.of(context).size.width,
                  )
                ],
              ),


            ),

          ],
        ),
      )
    );
  }

  ScrollController scontrol = new ScrollController();
  Widget buildList(AsyncSnapshot<ItemModel> snapshot) {
    /*return GridView.builder(
        itemCount: snapshot.data.results.length,
        gridDelegate:
        new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (BuildContext context, int index) {
          return Image.network(
            'https://image.tmdb.org/t/p/w185${snapshot.data
                .results[index].poster_path}',
            fit: BoxFit.cover,
          );
        });*/
    var posts = snapshot.data.results;
    return new ListView.builder(
      controller: scontrol,
        itemCount: posts.length,
        itemBuilder: (BuildContext context, int i) {
          return new GestureDetector(
            onHorizontalDragUpdate: (DragUpdateDetails details){
              if(details.delta.direction > 1.0 && details.delta.dx < -25){
                currentPostId = posts[i].id;
                showComments(context);
              }
            },//TODO: Add a new fling animation for vertical scrolling
            child: new Container(
                child: new Card(
                    child: new Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          new Padding(
                              child: new Text(
                                  "\u{1F44D} ${posts[i].points}    \u{1F60F} ${posts[i].author}",
                                  textAlign: TextAlign.right,
                                  textScaleFactor: 1.0,
                                  style: new TextStyle(
                                      color: Colors.black.withOpacity(0.6))),
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, top: 16.0)),
                          new Padding(
                              child: new Text(
                                posts[i].title.toString(),
                                style: new TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18.0),
                                textScaleFactor: 1.0,
                              ),
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, top: 16.0)),
                          const SizedBox(
                            height: 10.0,
                          ),
                          new ButtonTheme.bar(
                              child: new ButtonBar(children: <Widget>[
                                new FlatButton(
                                    child: new Text("${posts[i].comments} comments"),
                                    onPressed: () {
                                      currentPostId = posts[i].id;
                                      showComments(context);
                                    }),
                                !posts[i].self
                                    ? new FlatButton(
                                    child: new Text("\u{1F517} Open"),
                                    onPressed: () {
                                      if (!posts[i].self) launch(posts[i].url);
                                    })
                                    : null
                              ]))
                        ])),
                padding: const EdgeInsets.only(
                    left: 0.0, right: 0.0, top: 8.0, bottom: 0.0)
            ),
          );
        });
  }

  void showComments(BuildContext context) {
    Navigator.push(context, SlideRightRoute(widget: commentsList()));
  }


}
