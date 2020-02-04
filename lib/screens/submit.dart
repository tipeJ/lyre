import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:draw/draw.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Themes/themes.dart';
import 'package:lyre/screens/rules.dart';
import '../Resources/RedditHandler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:lyre/widgets/widgets.dart';
import '../Resources/globals.dart';
import '../Resources/reddit_api_provider.dart';


enum SubmitType{
  Selftext,
  Link,
  Image,
  //Video
}

class SubmitWindow extends StatefulWidget{
  final String initialTargetSubreddit;

  const SubmitWindow({this.initialTargetSubreddit = ""});

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
    _subredditController.text = widget.initialTargetSubreddit;

    _titleController = TextEditingController();

    _urlController = TextEditingController();

    _selfTextTabController = new TabController(vsync: this, length: 2);

    _selfTextTabExpansionController = AnimationController(value: _submitType == SubmitType.Selftext ? 1.0 : 0.0, vsync: this, duration: Duration(milliseconds: 400),);
    
    _inputOptionsExpansionController = AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    _selfTextFocusNode = FocusNode();
    _selfTextFocusNode.addListener(() {
      _inputOptionsExpansionController.animateTo(_selfTextFocusNode.hasFocus ? 1.0 : 0.0, curve: Curves.ease);
    });

    _selfTextTabController.index = 0;

    _selfTextController = TextEditingController();

    _selfTextController.addListener((){
      setState(() {
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

  bool _sendReplies = true;
  bool _isNsfw = false;
  bool _isSpoiler = true;

  TabController _selfTextTabController;

  ScrollController _scrollController;

  @override
  Widget build(BuildContext context){
    return new WillPopScope(
      onWillPop: _willPop,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Create a Submission"),
          actions: <Widget>[_sendingState == SendingState.Inactive
            ? IconButton(
              icon: const Icon(Icons.send),
              onPressed: (){
                if(PostsProvider().isLoggedIn() && _sendingState != SendingState.Sending){
                  setState(() {
                    _sendingState = SendingState.Sending;
                  });
                  switch (_submitType) {
                    case SubmitType.Selftext:
                      submitSelf(_subredditController.text, _titleController.text, _selfTextController.text, _isNsfw, _sendReplies).then((submission){
                        setState(() {
                          _sendingState = SendingState.Inactive;
                        });
                        if (submission is String){
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                        } else {
                          _showComments(context, submission);
                        }
                      });
                      break;
                    case SubmitType.Link:
                      submitLink(_subredditController.text, _titleController.text, _urlController.text, _isNsfw, _sendReplies).then((submission){
                        setState(() {
                          _sendingState = SendingState.Inactive;
                        });
                        if (submission is String){
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                        } else {
                          _showComments(context, submission);
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
                      submitImage(_subredditController.text, _titleController.text, _isNsfw, _sendReplies, _image).then((submission){
                        setState(() {
                          _sendingState = SendingState.Inactive;
                        });
                        if (submission is String){
                          Scaffold.of(context).showSnackBar(SnackBar(content: Text(submission),));
                        } else {
                          _showComments(context, submission);
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
        : CircularProgressIndicator()],
        ),
        body: Stack(
          children: [
            NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, b) {
                return [
                  SliverList(
                    delegate: SliverChildListDelegate([
                      TextField(
                        style: Theme.of(context).textTheme.body1,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 5.0),
                          labelText: "Title",
                        ),
                        controller: _titleController,
                      ),
                      Stack(
                        children: [
                          TextField(
                            style: Theme.of(context).textTheme.body1,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.only(left: 5.0, right: 85.0),
                              helperText: "Choose your subreddit",
                              hintText: 'r/'
                            ),
                            controller: _subredditController,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 85.0,
                              child: OutlineButton(
                                child: Text("Rules", style: TextStyle(color: Theme.of(context).textTheme.body2.color)),
                                onPressed: (){
                                  showDialog(
                                    context: context,
                                    child: Padding(
                                      child: RulesScreen(subreddit: _subredditController.text, parentContext: context,),
                                      padding: const EdgeInsets.all(50.0)
                                    )
                                  );
                                },
                              )
                            ),
                          )
                        ]
                      ),
                      IntrinsicWidth( 
                        child: Container(
                          padding: EdgeInsets.all(5.0),
                          alignment: Alignment.centerLeft,
                          child: ToggleButtons(
                            renderBorder: true,
                            constraints: BoxConstraints.tightFor(height: 30),
                            borderRadius: BorderRadius.circular(10.0),
                            isSelected: [
                              _isNsfw,
                              _sendReplies,
                              _isSpoiler
                            ],
                            textStyle: Theme.of(context).textTheme.body1,
                            children: <Widget>[
                              const Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3.5),
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
                                    _isNsfw = !_isNsfw;
                                    break;
                                  case 1:
                                    _sendReplies = !_sendReplies;
                                    break;
                                  default:
                                    _isSpoiler = !_isSpoiler;
                                    break;
                                }
                              });
                            },
                          )
                        )
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: ToggleButtons(
                          renderBorder: false,
                          constraints: BoxConstraints.expand(
                            width: (MediaQuery.of(context).size.width - 36) / 3,
                            height: 38.0
                          ),
                          isSelected: [
                            _submitType == SubmitType.Selftext,
                            _submitType == SubmitType.Link,
                            _submitType == SubmitType.Image,
                            //_submitType == SubmitType.Video,
                          ],
                          children: const <Widget>[
                            Text('Text'),
                            Text('Link'),
                            Text('Image'),
                            //const Text('Video'),
                          ],
                          selectedColor: Theme.of(context).accentColor,
                          color: Theme.of(context).textTheme.body1.color,
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
                                  //_submitType = SubmitType.Video;
                                  _handleSubmitTypeChange(selfText: false);
                                  break;
                              }
                            });
                          },
                        )
                      ),
                      SizeTransition(
                        axis: Axis.vertical,
                        sizeFactor: _selfTextTabExpansionController,
                        child: Column(
                          children: [
                            const Divider(indent: 10.0, endIndent: 10.0),
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

  void _showComments(BuildContext context, Submission submission) {
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
          scrollController: _scrollController,
          style: Theme.of(context).textTheme.body1,
          decoration: InputDecoration(
            hintText: "Your Text Here",
            contentPadding: const EdgeInsets.symmetric(horizontal: 5.0)
          ),
          controller: _selfTextController,
        ),
        _selfTextController.text.isNotEmpty 
          ? Padding(
            padding: EdgeInsets.all(10.0),
            child: MarkdownBody(
              data: _selfTextController.text,
              styleSheet: LyreTextStyles.getMarkdownStyleSheet(context),
            ) 
          )
          : const Center(child: Text("Markdown is Cool!"),)
      ],
    );
  }
  
  Widget _linkInputWidget(){
    return TextField(
      controller: _urlController,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 5.0),
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