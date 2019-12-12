import 'dart:math';

import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:draw/draw.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../Resources/RedditHandler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../Resources/globals.dart';
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
  SubmitType _submitType = SubmitType.Selftext;
  SendingState _sendingState = SendingState.Inactive;

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
  
  ///Controller for expanding the Edit/Preview TabBar
  AnimationController _selfTextTabExpansionController;

  TextEditingController _selfTextController;
  FocusNode _selfTextFocusNode;

  TextEditingController _urlController;
  TextEditingController _subredditController;
  TextEditingController _titleController;

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
    _subredditController.text = currentSubreddit;

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

    _selfTextController = TextEditingController();

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

  Future<bool> _willPop(){
    if(_sendingState == SendingState.Sending){
      return Future.value(false);
    }
    return Future.value(true);
  }

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
                  SliverAppBar(
                    primary: true,
                    floating: true,
                    titleSpacing: 0.0,
                    automaticallyImplyLeading: false,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Navigator.of(context).maybePop();
                      },
                    ),
                    title: Row(children: <Widget>[
                      Expanded(
                        child: TextField(
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
                            labelText: _subredditController.text.isNotEmpty ? "Title For Your Submission in r/${_subredditController.text}" : "Title",
                          ),
                          controller: _titleController,
                        ),
                      ),
                      _sendingState == SendingState.Inactive
                        ? IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: (){
                            if(PostsProvider().isLoggedIn() && _sendingState != SendingState.Sending){
                              setState(() {
                                _sendingState = SendingState.Sending;
                              });
                              switch (_submitType) {
                                case SubmitType.Selftext:
                                  submitSelf(_subredditController.text, _titleController.text, markdownData, is_nsfw, send_replies).then((submission){
                                    setState(() {
                                      _sendingState = SendingState.Inactive;
                                    });
                                    if (submission is String){
                                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                                    } else {
                                      showComments(context, submission);
                                    }
                                  });
                                  break;
                                case SubmitType.Link:
                                  submitLink(_subredditController.text, _titleController.text, _urlController.text, is_nsfw, send_replies).then((submission){
                                    setState(() {
                                      _sendingState = SendingState.Inactive;
                                    });
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
                                    setState(() {
                                      _sendingState = SendingState.Inactive;
                                    });
                                    if (submission is String){
                                      Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                                    } else {
                                      showComments(context, submission);
                                    }
                                  });
                                  break;
                                default:
                                //Video
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
                    : CircularProgressIndicator()
                    ],)
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
                        child: IntrinsicWidth( 
                          child: Align(
                            alignment: Alignment.center,
                            child: ToggleButtons(
                              renderBorder: false,
                              constraints: BoxConstraints.expand(
                                width: (MediaQuery.of(context).size.width - 36) / 3,
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
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: Align(
                          alignment: Alignment.center,
                          child: ToggleButtons(
                            renderBorder: false,
                            constraints: BoxConstraints.expand(
                              width: (MediaQuery.of(context).size.width - 36) / 4,
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
                              indicatorColor: Colors.transparent,
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
                    child: InputOptions(controller: _selfTextController,)
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
          decoration: InputDecoration(
            hintText: "Your Text Here",
            contentPadding: EdgeInsets.symmetric(horizontal: 5.0)
          ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            InkWell(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text("Pick From Gallery")
              ),
              onTap: (){
                getImage(ImageSource.gallery);
              },
            ),
            InkWell(
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Text("Open Camera")
              ),
              onTap: (){
                getImage(ImageSource.camera);
              },
            )
          ],
        ),
        _image == null
          ? const Center(child: Padding(child: Text('No image selected.'), padding: EdgeInsets.only(top: 10.0),),)
          : Image.file(_image)
      ],
    );
  }
}

class InputOptions extends StatelessWidget {
  final TextEditingController controller;

  String get _text => controller.text;
  set _text(s) => controller.text = s;


  const InputOptions({@required this.controller, key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Row(children: _buttons,),
      scrollDirection: Axis.horizontal,
    );
  }

  List<Widget> get _buttons => [
    IconButton(
      icon: Icon(Icons.format_bold),
      onPressed: _handleBoldClick,
    ),
    IconButton(
      icon: Icon(Icons.format_clear),
      onPressed: (){},
    ),
    IconButton(
      icon: Icon(Icons.format_italic),
      onPressed: (){

      },
    ),
    
  ];

  void _handleBoldClick() {
    var text = controller.text;
    final initialLength = text.length;
    final initialOffset = controller.selection.base.offset-1;
    print(initialLength.toString() + ':' + controller.selection.base.offset.toString());
    if (controller.selection.isCollapsed) {
      if (text.isNotEmpty && (text[min(initialOffset, initialLength-1)] == '*' || text[max(initialOffset+1, 0)] == '*')) {
        print('asdasdasd');
        int start = _firstOccurrence(char: '*', startIndex: max(initialOffset, 0), direction: -1);
        int end = _firstOccurrence(char: '*', startIndex: min(initialOffset, initialLength), direction: 1);
        print('first: ' + start.toString() + '\n last: ' + end.toString());
        _text = text.replaceRange(
          start-1, 
          end+1, 
          text.substring(start+1, end));
      } else {
        text += ' ** ';
        controller.text = text;
        controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+3));
      }
    }
  }

  int _firstOccurrence({String char, int startIndex, int direction}) {
    for (var i = startIndex; (direction < 0) ? i > 0 : i < _text.length; direction < 0 ? i-- : i++) {
      if (_text[i] == char) {
        return i;
      }
    }
    return direction < 0 ? 0 : _text.length-1;
  }
  String _replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) + newChar + oldString.substring(index + 1);
  }

}