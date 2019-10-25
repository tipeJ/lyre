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
        expandedBarHeight; //<-- Update the _expansionController.value by the movement done by user.
  }

  void _reverseExpanded() {
    _expansionController.fling(velocity: -2.0);
    isExpanded = false;
  }

  void _handleExpandedDragEnd(DragEndDetails details) {
    if (_expansionController.status == AnimationStatus.completed) {
      isExpanded = true;
    }
    if (_expansionController.isAnimating ||
        _expansionController.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy /
        expandedBarHeight; //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      _expansionController.fling(
          velocity: max(2.0, -flingVelocity)); //<-- either continue it upwards
      isExpanded = true;
    } else if (flingVelocity > 0.0) {
      _expansionController.fling(
          velocity: min(-2.0, -flingVelocity)); //<-- or continue it downwards
      isExpanded = false;
    } else
      _expansionController.fling(
          velocity: _expansionController.value < 0.5
              ? -2.0
              : 2.0); //<-- or just continue to whichever edge is closer
  }
  bool isExpanded = false;
  double expandedBarHeight = 100.0;

  @override
  void initState() { 
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
      height: lerp(0, expandedBarHeight),
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        itemCount: widget.controller.images.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, i){
          final url = widget.controller.images[i].thumbnailUrl;
          if (url != null && getLinkType(url) == LinkType.DirectImage){
            return InkWell(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 3.0),
                width: 75.0,
                height: expandedBarHeight,
                child: Stack(children: <Widget>[
                  Image(
                    image: AdvancedNetworkImage(
                      url,
                      useDiskCache: true,
                      cacheRule: CacheRule(maxAge: Duration(days: 7))
                    ),
                    fit: BoxFit.cover,
                  ),
                  Container(color: i == widget.controller.currentIndex ? Colors.black38 : Colors.transparent),
                ],)
              ),
              onTap: (){
                setState(() {
                  widget.controller.setCurrentIndex(i);                
                });
              },
            );
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