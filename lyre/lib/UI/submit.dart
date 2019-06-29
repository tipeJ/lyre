import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:zefyr/zefyr.dart';
import '../Resources/globals.dart';

class SubmitWindow extends StatefulWidget{

  State<SubmitWindow> createState() => new SubmitWidgetState();
}

class SubmitWidgetState extends State<SubmitWindow>{
  String subReddit = currentSubreddit;
  bool popReady = false;

  @override void initState() {
    _subredditController  = TextEditingController();
    _subredditController.text = subReddit;

    _focusNode = new FocusNode();
    final document = new NotusDocument();
    _zefyrController = new ZefyrController(document);
    super.initState();
  }

  FocusNode _focusNode;
  ZefyrController _zefyrController;

  Future<bool> _willPop(){
    if(popReady){
      return Future.value(true);
    }
    return Future.value(false);
  }
  
  var _subredditController;

  @override
  Widget build(BuildContext context){
    return new WillPopScope(
      onWillPop: _willPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Submit to r/${subReddit}"),
        ),
        resizeToAvoidBottomInset: true,
        body: Container(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextField(
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  helperText: "Write your title here"
                ),
              ),
              TextField(
                decoration: InputDecoration(
                  helperText: "Choose your subreddit",
                ),
                controller: _subredditController,
              ),
              DefaultTabController(
                length: 4,
                child: Column(
                    children: <Widget>[
                      TabBar(
                        tabs: <Widget>[
                          Tab(
                            icon: Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.text_fields),
                            ),
                          ),
                          Tab(
                            icon: Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.link),
                            ),
                          ),
                          Tab(
                            icon: Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.image)
                            ),
                          ),
                          Tab(
                            icon: Padding(
                              padding: EdgeInsets.all(6.0),
                              child: Icon(Icons.videocam),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 400.0,
                        child: TabBarView(
                          children: <Widget>[
                            MarkdownInputWidget(),
                            Container(
                              color: Colors.pink,
                            ),
                            Container(
                              color: Colors.green,
                            ),
                            Container(
                              color: Colors.purple,
                            ),
                          ],
                        ),
                      ),
                      /*
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          RaisedButton(
                            child: Text('Cancel'),
                            onPressed: (){

                            },
                          ),
                          RaisedButton(
                            child: Text('Submit'),
                            onPressed: (){
                              
                            },
                          ),
                        ],
                      )
                      */
                    ],
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget MarkdownInputWidget(){
    return Container(
      child: /*Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextField(
            keyboardType: TextInputType.multiline,
          ),
          Container(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: new Row(
                children: getInputOptions(),
              ),
            ),
            color: Colors.black45,
          )
        ],
      ),*/
      ZefyrScaffold(
        child: ZefyrEditor(
          controller: _zefyrController,
          focusNode: _focusNode,
        ),
      ),
      padding: EdgeInsets.only(
        bottom: 10.0

      ),
    );
  }
  List<Widget> getInputOptions(){
    return [
      IconButton(
        icon: Icon(Icons.format_bold),
        onPressed: (){

        },
      ),
      IconButton(
        icon: Icon(Icons.format_clear),
        onPressed: (){

        },
      ),
      IconButton(
        icon: Icon(Icons.format_italic),
        onPressed: (){

        },
      ),
    ];
  }
}