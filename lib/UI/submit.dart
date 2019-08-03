import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:draw/draw.dart';
import '../Models/Post.dart';
import '../Resources/RedditHandler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Resources/globals.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:markdown/markdown.dart' as prefix0;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import '../Resources/reddit_api_provider.dart';


enum SubmitType{
  Selftext,
  Link,
  Image,
  Video
}

class SubmitWindow extends StatefulWidget{

  State<SubmitWindow> createState() => new SubmitWidgetState();
}

class SubmitWidgetState extends State<SubmitWindow> with SingleTickerProviderStateMixin{
  String subReddit = currentSubreddit;
  bool popReady = true;

  File _image;

  Future getImage(ImageSource source) async {
    var image = await ImagePicker.pickImage(
      source: source,
      imageQuality: 75
      );

    setState(() {
     _image = image; 
    });
  }
  
  SubmitType _submitType;

  @override void initState() {
    _subredditController  = TextEditingController();
    _subredditController.text = subReddit;

    _titleController = TextEditingController();

    _urlController = TextEditingController();

    _tabController = new TabController(vsync: this, length: 4);
    _tabController.addListener((){
      switch (_tabController.index) {
        case 1:
          _submitType = SubmitType.Link;
          break;
        case 2:
          _submitType = SubmitType.Image;
          break;
        case 3:
          _submitType = SubmitType.Video;
          break;
        default:
          _submitType = SubmitType.Selftext;
      }
    });
    _tabController.index = 0;

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
  
  TextEditingController _urlController;
  TextEditingController _subredditController;
  TextEditingController _titleController;

  bool send_replies = true;
  bool is_nsfw = false;

  String markdownData = "";

  TabController _tabController;

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
                          content: getPreviewWidget(),
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
              Builder(
                builder: (BuildContext context){
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.0),
                    child: InkWell(
                      child: Icon(Icons.send),
                      onTap: (){
                          if(PostsProvider().isLoggedIn()){
                            switch (_submitType) {
                              case SubmitType.Selftext:
                                submitSelf(_subredditController.text, _titleController.text, markdownData, is_nsfw, send_replies).then((sub){
                                  showComments(context, sub);
                                });
                                break;
                              case SubmitType.Link:
                                submitLink(_subredditController.text, _titleController.text, _urlController.text, is_nsfw, send_replies).then((submission){
                                  showComments(context, submission);
                                });
                                break;
                              case SubmitType.Image:
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context){
                                    return AlertDialog(
                                        title: Text('Uploading image'),
                                        content: Container(
                                            width: 25.0,
                                            height: 25.0,
                                            child: Center(
                                              child: CircularProgressIndicator()
                                            )
                                          )
                                      );
                                  }
                                );
                                submitImage(_subredditController.text, _titleController.text, is_nsfw, send_replies, _image).then((submission){
                                  showComments(context, submission);
                                });
                                break;
                              default:
                          }
                        }else{
                          final snackBar = SnackBar(
                            content: Text('Log in to create submissions'),
                          );
                          Scaffold.of(context).showSnackBar(snackBar);
                        }
                      },
                    ),
                  );
                },
              )
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: Container(
          padding: EdgeInsets.symmetric(horizontal: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width/2,
                    child: TextField(
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        helperText: "Write your title here"
                      ),
                      controller: _titleController,
                    ),
                  ),
                  Row(children: <Widget>[
                    Text('Send replies:'),
                    Switch.adaptive(
                      value: send_replies,
                      onChanged: (_){
                        send_replies = _;
                      },
                    )
                  ],)
                 
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width/2,
                    child: TextField(
                      decoration: InputDecoration(
                        helperText: "Choose your subreddit",
                        prefixText: 'r/'
                      ),
                      controller: _subredditController,
                    ),
                  ),
                  Row(children: <Widget>[
                    Text('NSFW:'),
                    Switch.adaptive(
                      value: is_nsfw,
                      onChanged: (_){
                        is_nsfw = _;
                      },
                    )
                  ],)
                ],
              ),
              TabBar(
                controller: _tabController,
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
                  controller: _tabController,
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
            ],
          ),
        ),
      ),
    );
  }
  Widget getPreviewWidget(){
    switch (_submitType) {
      case SubmitType.Selftext:
        return MarkdownBody(
          data: markdownData,
        ); 
        break;
      case SubmitType.Link:
        return InAppWebView(
            initialUrl: _urlController.text
          );
        break;
      case SubmitType.Image:
        return _image != null ? Image.file(_image) : Container();
      default:
        return Container();
    }
  }
  void showComments(BuildContext context, Submission submission) {
    Post inside = Post.fromApi(submission);
    cPost = inside;
    currentPostId = submission.id;
    inside.expanded = true;
    Navigator.of(context).pushReplacementNamed('/comments');
  }
  var _xControl = TextEditingController();
  Widget SelftextInputWidget(){
    return Container(
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: TextField(
              keyboardType: TextInputType.multiline,
              maxLines: null,
              controller: _xControl,
          ),
          ),
          SliverToBoxAdapter(
            child: Container(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: new Row(
                  children: getInputOptions(),
                ),
              ),
              color: Colors.black45,
            ),
          )
        ],
      )
    );
  }
  
  Widget LinkInputWidget(){
    return Container(
      child: TextField(
        controller: _urlController,
        decoration: InputDecoration(
          helperText: 'Source URL of link'
        ),
      )
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