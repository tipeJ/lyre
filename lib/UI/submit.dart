import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:draw/draw.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import '../Resources/RedditHandler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Resources/globals.dart';
import 'package:markdown/markdown.dart' as prefix0;
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

class SubmitWidgetState extends State<SubmitWindow> with TickerProviderStateMixin{
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
  
  SubmitType _submitType = SubmitType.Selftext;
  
  ///Controller for expanding the Edit/Preview TabBar
  AnimationController _selfTextTabExpansionController;

  var _selfTextController = TextEditingController();

  FocusNode _selfTextFocusNode;
  AnimationController _inputOptionsExpansionController;

  _handleSubmitTypeChange({bool selfText}) {
    if (selfText) {
      _selfTextTabExpansionController.animateTo(1.0, curve: Curves.ease);
    } else {
      _selfTextTabExpansionController.animateTo(0.0, curve: Curves.ease);
    }
  }

  @override void initState() {
    _subredditController  = TextEditingController();
    _subredditController.addListener(() {
      setState((){});
    });
    _subredditController.text = subReddit;

    _titleController = TextEditingController();

    _urlController = TextEditingController();

    _selfTextTabController = new TabController(vsync: this, length: 2);

    _selfTextTabExpansionController = AnimationController(value: _submitType == SubmitType.Selftext ? 1.0 : 0.0, vsync: this, duration: Duration(milliseconds: 400),);
    
    _inputOptionsExpansionController = AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    _selfTextFocusNode = FocusNode();
    _selfTextFocusNode.addListener(() {
      print('animated' + (_selfTextFocusNode.hasFocus).toString());
      _inputOptionsExpansionController.animateTo(_selfTextFocusNode.hasFocus ? 1.0 : 0.0, curve: Curves.ease);
    });

    _selfTextTabController.index = 0;

    _selfTextController.addListener((){
      setState(() {
        markdownData = _selfTextController.text;
      });
    });
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() { 
    _urlController.dispose();
    _titleController.dispose();
    _scrollController.dispose();
    _selfTextController.dispose();
    _subredditController.dispose();
    _selfTextTabController.dispose();
    _selfTextTabExpansionController.dispose();
    _selfTextFocusNode.dispose();
    super.dispose();
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
  bool is_spoiler = true;

  String markdownData = "";

  TabController _selfTextTabController;

  ScrollController _scrollController;

  @override
  Widget build(BuildContext context){
    return new WillPopScope(
      onWillPop: _willPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, b) {
                return [
                  SliverSafeArea(
                    sliver: SliverAppBar(
                      primary: true,
                      floating: true,
                      titleSpacing: 0.0,
                      automaticallyImplyLeading: false,
                      title: Row(children: <Widget>[
                        Expanded(
                          child: TextField(
                            textInputAction: TextInputAction.send,
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                              labelText: _subredditController.text.isNotEmpty ? "Title For Your Post in r/${_subredditController.text}" : "Title",
                            ),
                            controller: _titleController,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send),
                          onPressed: (){
                            if(PostsProvider().isLoggedIn()){
                              switch (_submitType) {
                                case SubmitType.Selftext:
                                  submitSelf(_subredditController.text, _titleController.text, markdownData, is_nsfw, send_replies).then((submission){
                                    if (submission is String){
                                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                                    } else {
                                      showComments(context, submission);
                                    }
                                  });
                                  break;
                                case SubmitType.Link:
                                  submitLink(_subredditController.text, _titleController.text, _urlController.text, is_nsfw, send_replies).then((submission){
                                    if (submission is String){
                                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                                    } else {
                                      showComments(context, submission);
                                    }
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
                                    if (submission is String){
                                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                                    } else {
                                      showComments(context, submission);
                                    }
                                  });
                                  break;
                                default:
                                  break;
                            }
                          } else {
                            final snackBar = const SnackBar(
                              content: Text('Log in to create submissions'),
                            );
                            Scaffold.of(context).showSnackBar(snackBar);
                          }
                        },
                        )
                      ],)
                    )
                  ),
                  SliverList(
                  delegate: SliverChildListDelegate([
                      TextField(
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                          helperText: "Choose your subreddit",
                          hintText: 'r/'
                        ),
                        controller: _subredditController,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: ToggleButtons(
                            constraints: BoxConstraints.expand(
                              width: MediaQuery.of(context).size.width / 3.5,
                              height: 38.0
                            ),
                            isSelected: [
                              is_nsfw,
                              send_replies,
                              is_spoiler
                            ],
                            children: <Widget>[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.5),
                                child: Text('NSFW')
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.5),
                                child: Text('Send Replies')
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.5),
                                child: Text('Spoiler')
                              ),
                            ],
                            onPressed: (i) {
                              setState(() {
                                switch (i) {
                                  case 0:
                                    is_nsfw = !is_nsfw;
                                    break;
                                  case 1:
                                    send_replies = !send_replies;
                                    break;
                                  default:
                                    is_spoiler = !is_spoiler;
                                    break;
                                }
                              });
                            },
                          )
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: ToggleButtons(
                            constraints: BoxConstraints.expand(
                              width: MediaQuery.of(context).size.width / 4.5,
                              height: 38.0
                            ),
                            isSelected: [
                              _submitType == SubmitType.Selftext,
                              _submitType == SubmitType.Link,
                              _submitType == SubmitType.Image,
                              _submitType == SubmitType.Video,
                            ],
                            children: <Widget>[
                              const Text('Text'),
                              const Text('Link'),
                              const Text('Image'),
                              const Text('Video'),
                            ],
                            onPressed: (i) {
                              if (_submitType != SubmitType.values[i]) setState(() {
                                switch (i) {
                                  case 0:
                                    _submitType = SubmitType.Selftext;
                                    _handleSubmitTypeChange(selfText: true);
                                    break;
                                  case 1:
                                    _submitType = SubmitType.Link;
                                    _handleSubmitTypeChange(selfText: false);
                                    break;
                                  case 2:
                                    _submitType = SubmitType.Image;
                                    _handleSubmitTypeChange(selfText: false);
                                    break;
                                  default:
                                    _submitType = SubmitType.Video;
                                    _handleSubmitTypeChange(selfText: false);
                                    break;
                                }
                              });
                            },
                          )
                        )
                      ),
                      SizeTransition(
                        axis: Axis.vertical,
                        sizeFactor: _selfTextTabExpansionController,
                        child: Column(
                          children: [
                            Divider(),
                            TabBar(
                              controller: _selfTextTabController,
                              tabs: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text('Edit')
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text('Preview')
                                ),
                              ],
                            )
                          ]
                        ),
                      )
                    ]
                  ),
                ),];
              },
              body: _getInputWidget()
            ),
            Positioned(
              bottom: 0.0,
              child: SizeTransition(
                sizeFactor: _inputOptionsExpansionController,
                child: Material(
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    color: Theme.of(context).primaryColor,
                    child: SingleChildScrollView(
                      child: Row(children: _getInputOptions,),
                      scrollDirection: Axis.horizontal,
                    )
                  )
                ),
              )
            )
          ]
        ),
      ),
    );
  }

  Widget _getInputWidget() {
    switch (_submitType) {
      case SubmitType.Selftext:
        return _selftextInputWidget();
      case SubmitType.Link:
        return _linkInputWidget();
      case SubmitType.Image:
        return _imageInputWidget();
      default:
        return const Center(child: Text('TO BE IMPLEMENTED'),);
    }
  }
  Widget _getPreviewWidget(){
    switch (_submitType) {
      case SubmitType.Selftext:
        return MarkdownBody(data: _selfTextController.text,);
      case SubmitType.Link:
        return InAppWebView(
            initialUrl: _urlController.text
          );
      case SubmitType.Image:
        return _image != null ? Image.file(_image) : Container();
      default:
        return Container();
    }
  }

  void showComments(BuildContext context, Submission submission) {
    Navigator.of(context).pushReplacementNamed('comments', arguments: submission);
  }

  Widget _selftextInputWidget(){
    return TabBarView(
      controller: _selfTextTabController,
      children: <Widget>[
        TextField(
          keyboardType: TextInputType.multiline,
          focusNode: _selfTextFocusNode,
          maxLines: null,
          controller: _selfTextController,
        ),
        _selfTextController.text.isNotEmpty 
          ? Padding(
            padding: EdgeInsets.all(10.0),
            child: MarkdownBody(data: _selfTextController.text,) 
          )
          : const Center(child: Text("Markdown is Cool!"),)
      ],
    );
  }
  
  Widget _linkInputWidget(){
    return TextField(
      controller: _urlController,
      decoration: const InputDecoration(
        helperText: 'Source URL of link'
      ),
    );
  }

  Widget _imageInputWidget(){
    return ListView(
      children:[
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
          ? Center(child: Text('No image selected.'))
          : Image.file(_image)
      ],
    );
  }

  List<Widget> get _getInputOptions => [
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