import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:draw/draw.dart';
import '../Models/Post.dart';
import '../Resources/RedditHandler.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Resources/globals.dart';

class SubmitWindow extends StatefulWidget{

  State<SubmitWindow> createState() => new SubmitWidgetState();
}

class SubmitWidgetState extends State<SubmitWindow>{
  String subReddit = currentSubreddit;
  bool popReady = true;

  File _image;

  Future getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);

    setState(() {
     _image = image; 
    });
  }
  

  @override void initState() {
    _subredditController  = TextEditingController();
    _subredditController.text = subReddit;

    _titleController = TextEditingController();

    /*
    _focusNode = new FocusNode();
    final document = new NotusDocument();
    _zefyrController = new ZefyrController(document);
    */
    _xControl.addListener((){
      setState(() {
        markdownData = _xControl.text;
      });
    });
    super.initState();
  }

  /*
  FocusNode _focusNode;
  ZefyrController _zefyrController;
  */
  Future<bool> _willPop(){
    if(popReady){
      return Future.value(true);
    }
    return Future.value(false);
  }
  
  TextEditingController _subredditController;
  TextEditingController _titleController;

  String markdownData = "";

  @override
  Widget build(BuildContext context){
    return new WillPopScope(
      onWillPop: _willPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Submit to r/${_subredditController.text}"),
          actions: <Widget>[
              InkWell(
                  child: Icon(Icons.remove_red_eye),
                  onTap: (){
                    showDialog(
                      context: context,
                      builder: (BuildContext context){
                        return AlertDialog(
                          title: Text(_titleController.text),
                          content: MarkdownBody(
                                data: markdownData,
                              ),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Close'),
                              onPressed: (){
                                Navigator.of(context).pop();
                              },
                            )
                          ],
                        );
                      }
                    );
                  },
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: InkWell(
                  child: Icon(Icons.send),
                  onTap: (){
                    submitSelf(_subredditController.text, _titleController.text, markdownData).then((sub){
                      showComments(context, sub);
                    });
                  },
                ),
              ),
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              TextField(
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  helperText: "Write your title here"
                ),
                controller: _titleController,
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
                        height: 500.0,
                        child: TabBarView(
                          children: <Widget>[
                            SelftextInputWidget(),
                            LinkInputWidget(),
                            ImageInputWidget(),
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
  void showComments(BuildContext context, Submission sub) {
    Post inside = Post.fromApi(sub);
    cPost = inside;
    inside.expanded = true;
    Navigator.of(context).pushNamed('/comments');
  }
  var _xControl = TextEditingController();
  Widget SelftextInputWidget(){
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          TextField(
            keyboardType: TextInputType.multiline,
            controller: _xControl,
          ),
          Container(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: new Row(
                children: getInputOptions(),
              ),
            ),
            color: Colors.black45,
          ),
          
        ],
      ),
      /*
      ZefyrScaffold(
        child: ZefyrEditor(
          controller: _zefyrController,
          focusNode: _focusNode,
        ),
      ),
      */
    );
  }
  
  Widget LinkInputWidget(){
    return Container(
      child: TextField(
        decoration: InputDecoration(
          helperText: 'Source URL of link'
        ),
      ),
    );
  }

  Widget ImageInputWidget(){
    return CustomScrollView(
      slivers: <Widget>[
        SliverList(
          delegate: SliverChildListDelegate([
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  InkWell(
                    child: Icon(Icons.image),
                    onTap: (){
                      getImage(ImageSource.gallery);
                    },
                  ),
                  InkWell(
                    child: Icon(Icons.camera),
                    onTap: (){
                      getImage(ImageSource.camera);
                    },
                  )
                ],
              ),
              padding: EdgeInsets.symmetric(vertical: 15.0),
            ),
            _image == null
            ? Text('No image selected.')
            : Image.file(_image)
          ]),
              )
      ],
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