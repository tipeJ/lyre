import 'dart:math';
import 'dart:ui' as prefix0;

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lyre/Models/image.dart';
import 'package:lyre/UploadUtils/ImgurAPI.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageViewer extends StatelessWidget {
  Submission submission;
  LinkType linkType;
  String url;

  ImageViewer(String url, [Submission submission]){
    this.url = url;
    linkType = getLinkType(url);
    if (submission != null){
      this.submission = submission;
    }
  }

  AlbumController albumController;

  @override
  Widget build(BuildContext context) {
    if (albumLinkTypes.contains(linkType)){
      if (albumController != null) return AlbumViewer(albumController: albumController,);
      return FutureBuilder(
        future: ImgurAPI().getAlbumPictures(url),
        builder: (context, AsyncSnapshot<List<LyreImage>> snapshot){
          if (snapshot.hasData){
            albumController = AlbumController(snapshot.data, submission, linkType);
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                AlbumViewer(albumController: albumController,),
                Positioned(
                  bottom: 0.0,
                  child: AlbumControlsBar(controller: albumController,),
                )
              ],
            );
          } else {
            return const Center(child: const CircularProgressIndicator(),);
          }
        },
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget> [
        SingleImageViewer(url),
        Positioned(
          bottom: 0.0,
          child: ImageControlsBar(submission: submission, url: url,),
        )
      ]
    );
  }
}

class AlbumController extends ChangeNotifier{
  List<LyreImage> images; //dynamic json response if Imgur album, otherwise a direct link URL string
  LinkType linkType;
  Submission submission;
  int currentIndex = 0;

  AlbumController(this.images, this.submission, this.linkType, [this.currentIndex]);

  void setCurrentIndex(int newIndex){
    currentIndex = newIndex;
    notifyListeners();
  }
}

class AlbumViewer extends StatefulWidget {
  final AlbumController albumController;
  AlbumViewer({Key key, this.albumController}) : super(key: key);

  _AlbumViewerState createState() => _AlbumViewerState();
}

class _AlbumViewerState extends State<AlbumViewer> {
  final pageController = PageController();

  @override
  void initState() { 
    widget.albumController.addListener((){
      setState(() {
        pageController.jumpToPage(widget.albumController.currentIndex);
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PhotoViewGallery.builder(
      pageController: pageController,
      itemCount: widget.albumController.images.length,
      builder: (context, i){
        final image = widget.albumController.images[i].url;
        switch (getLinkType(image)) {
          case LinkType.DirectImage:
            return PhotoViewGalleryPageOptions(
              minScale: 0.5,
              maxScale: 5.0,
              imageProvider: AdvancedNetworkImage(
                image,
                useDiskCache: true,
                cacheRule: const CacheRule(maxAge: Duration(days: 7))
              )
            );
          default:
            return PhotoViewGalleryPageOptions.customChild(
              childSize: MediaQuery.of(context).size,
              child: const Center(child: const Text("Media type not supported"),) //In case of unsupported formats.
            );
        }
      },
    );
  }
}

class SingleImageViewer extends StatelessWidget {
  final previewUrl;

  SingleImageViewer(this.previewUrl);
  
  @override
  Widget build(BuildContext context) {
    return PhotoView(
      minScale: 0.5,
      maxScale: 5.0,
      imageProvider: AdvancedNetworkImage(
        previewUrl,
        // TODO: IMPLEMENT loadingProgress indicator
        useDiskCache: true,
        cacheRule: const CacheRule(maxAge: Duration(days: 7)),
      ),
      loadingChild: const Center(child: const CircularProgressIndicator(),),
    );
  }
}
class AlbumControlsBar extends StatefulWidget {
  final AlbumController controller;
  AlbumControlsBar({Key key, this.controller}) : super(key: key);

  _AlbumControlsBarState createState() => _AlbumControlsBarState();
}

class _AlbumControlsBarState extends State<AlbumControlsBar> with SingleTickerProviderStateMixin{
  AnimationController _expansionController;

  double lerp(double min, double max) => prefix0.lerpDouble(min, max, _expansionController.value);

  void _handleExpandedDragUpdate(DragUpdateDetails details) {
    _expansionController.value -= details.primaryDelta /
        maxExpandedBarHeight; //<-- Update the _expansionController.value by the movement done by user.
  }

  void _reverseExpanded() {
    if (fullyExpanded) {
      _expansionController.animateBack(0.1, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      fullyExpanded = false;
      isExpanded = true;
    } else {
      _expansionController.fling(velocity: -2.0);
      fullyExpanded = false;
      isExpanded = false;
    }
  }

  void _handleExpandedDragEnd(DragEndDetails details) {
    if (_expansionController.status == AnimationStatus.completed) {
      fullyExpanded = true;
    }
    if (_expansionController.isAnimating ||
        _expansionController.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy /
        getExpandedBarHeight(); //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      if (_expansionController.value > 0.1) {
        _expansionController.animateTo(1.0, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve);//<-- either continue it upwards
        isExpanded = true;
        fullyExpanded = true;
      } else {
        _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve); //<-- either continue it upwards
        isExpanded = true;
        fullyExpanded = false;
      }
    } else if (flingVelocity > 0.0) {
      if (_expansionController.value > 0.1) {
        _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve); //<-- either continue it upwards
        isExpanded = true;
        fullyExpanded = false;
      } else {
        _expansionController.animateTo(0, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve); //<-- either continue it upwards
        isExpanded = false;
        fullyExpanded = false;
      }
    } else{
      if (_expansionController.value > 0.1) {
        if (_expansionController.value > 0.9 / 2) {
          _expansionController.animateTo(1.0, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve);
          isExpanded = true;
          fullyExpanded = true;
        } else {
          _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve);
          isExpanded = true;
          fullyExpanded = false;
        }
      } else {
        if (_expansionController.value > 0.05) {
          _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve);
          isExpanded = true;
          fullyExpanded = false;
        } else {
          _expansionController.animateTo(0.0, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve);
          isExpanded = false;
          fullyExpanded = false;
        }
      }
    }
        //<-- or just continue to whichever edge is closer
  }
  final Curve animationCurve = Curves.easeOutCirc;
  final int maxAnimationDuration = 400;
  final double minAnimationDuration = 150.0;

  // Flingvelocity is the velocity which the user ends the fling with. Boolean true if the animation is going upwards, false if downwards
  int getExpansionFlingDuration(bool up, double flingVelocity){
    final double animationDuration = min(maxAnimationDuration.toDouble(), max(maxAnimationDuration / (flingVelocity.abs() * 0.1), minAnimationDuration));
    if (_expansionController.value > 0.1) {
      return up ? (animationDuration * (1 - 0.75 * (_expansionController.value - 0.1))).round() : (animationDuration * 1.5 * (_expansionController.value - 0.1)).round();
    } else {
      return up ? (animationDuration * (1 - 10 * (_expansionController.value))).round() : (animationDuration * 1.25 * (10 * _expansionController.value)).round();      
    }
  }
  bool isExpanded = false;
  bool fullyExpanded = false;
  double getExpandedBarHeight(){
    return maxExpandedBarHeight * 0.1;
  }
  double maxExpandedBarHeight = 500.0; //Fallback value

  @override
  void initState() { 
    maxExpandedBarHeight = MediaQuery.of(context).size.height - 50.0; //Scren height minus the height of image controls bar
    _expansionController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 450),
    )..addListener((){
      setState(() { 
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       width: MediaQuery.of(context).size.width,
       child: GestureDetector(
         child: Column(children: <Widget>[
          getPreviewsBar(context),
          ImageControlsBar(submission: widget.controller.submission,)
        ],),
        onVerticalDragUpdate: _handleExpandedDragUpdate,
        onVerticalDragEnd: _handleExpandedDragEnd,
       )
    );
  }
  
  Widget getPreviewsBar(BuildContext context){
    return Container(
      height: lerp(0, maxExpandedBarHeight),
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        itemCount: widget.controller.images.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i){
          final url = widget.controller.images[i].thumbnailUrl;
          if (url != null && getLinkType(url) == LinkType.DirectImage){
            return StatefulBuilder(builder: (context, child){
              return InkWell(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 3.0),
                  width: 75.0,
                  height: getExpandedBarHeight(),
                  child: Stack(children: <Widget>[
                    Image(
                      image: AdvancedNetworkImage(
                        url,
                        useDiskCache: true,
                        cacheRule: CacheRule(maxAge: Duration(days: 7))
                      ),
                      fit: BoxFit.cover,
                    ),
                    Container(color: i == widget.controller.currentIndex ? Colors.black38 : Colors.transparent, height: getExpandedBarHeight(),),
                  ],)
                ),
                onTap: (){
                  setState(() {
                    widget.controller.setCurrentIndex(i);                
                  });
                },
              );
            },);
          }
          return Container();
        },
      ),
    );
  }
}

class ImageControlsBar extends StatelessWidget {
  final Submission submission;
  final String url;
  ImageControlsBar({Key key, this.submission, this.url} ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.0,
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildCopyButton(context),
          _buildOpenUrlButton(context),
          submission ?? _buildCommentsButton(context), //Only show comment button if the parent usercontent is a submission (Because otherwise there wouldn't be any comments to show)
          _buildDownloadButton(context),
          _buildShareButton(context),
        ],
      ),
    );
  }
  Widget _buildCopyButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.content_copy),
      color: Colors.white,
      onPressed: (){
        // TODO: Implement
      },
    );
  }
  Widget _buildOpenUrlButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.open_in_browser),
      color: Colors.white,
      onPressed: (){
        // TODO: Implement
      },
    );
  }
  Widget _buildCommentsButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.comment),
      color: Colors.white,
      onPressed: (){
        Navigator.of(context).pushNamed('comments', arguments: submission);
      },
    );
  }
  Widget _buildDownloadButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.file_download),
      color: Colors.white,
      onPressed: (){
        // TODO: Implement
      },
    );
  }
  Widget _buildShareButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.share),
      color: Colors.white,
      onPressed: (){
        // TODO: Implement
      },
    );
  }
}