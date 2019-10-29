import 'dart:math';
import 'dart:ui' as prefix0;

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix1;
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lyre/Models/image.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/UploadUtils/ImgurAPI.dart';
import 'package:lyre/utils/share_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

const selection_album = "Album";
const selection_image = "Image";

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
            albumController = AlbumController(snapshot.data, submission, url);
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
          child: ImageControlsBar(submission: submission, url: url, controller: null,),
        )
      ]
    );
  }
}

class AlbumController extends ChangeNotifier{
  List<LyreImage> images;
  String url;
  Submission submission;
  int currentIndex = 0;

  bool expanded = false;
  bool fullyExpanded = false;

  AlbumController(this.images, this.submission, this.url, [this.currentIndex]);

  void setCurrentIndex(int newIndex){
    currentIndex = newIndex;
    notifyListeners();
  }
  LyreImage currentImage(){
    return images[currentIndex];
  }

  void toggleExpand(){
    if (fullyExpanded){
      fullyExpanded = false;
      expanded = false;
    } else if (expanded) {
      fullyExpanded = true;
    } else {
      expanded = true;
    }
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
      if (pageController.page.round() != widget.albumController.currentIndex){
        setState(() {
          pageController.jumpToPage(widget.albumController.currentIndex);
        });
      }
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
    if(_expansionController.value == 1 && ((gridController.offset == 0.0 && details.delta.dy < 0.0) || gridController.offset != 0.0)){
      gridController.jumpTo(gridController.offset - details.delta.dy);
      //TODO: ! ADD CUSTOM FLING ANIMATION FOR GRID
    } else {
      _expansionController.value -= details.primaryDelta /
      maxExpandedBarHeight; //<-- Update the _expansionController.value by the movement done by user.
    }
    
  }

  void _reverseExpanded() {
    if (fullyExpanded()) {
      _expansionController.animateBack(0.1, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _expansionController.fling(velocity: -2.0);
    }
  }

  void _handleExpandedDragEnd(DragEndDetails details) {
    if (_expansionController.status == AnimationStatus.completed) {
    }
    if (_expansionController.isAnimating ||
        _expansionController.status == AnimationStatus.completed) return;

    final double flingVelocity = details.velocity.pixelsPerSecond.dy /
        getExpandedBarHeight(); //<-- calculate the velocity of the gesture
    if (flingVelocity < 0.0) {
      if (_expansionController.value > 0.1) {
        _expansionController.animateTo(1.0, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve);//<-- either continue it upwards
      } else {
        _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve); //<-- either continue it upwards
      }
    } else if (flingVelocity > 0.0) {
      if (_expansionController.value > 0.1) {
        _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve); //<-- either continue it upwards
      } else {
        _expansionController.animateTo(0, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve); //<-- either continue it upwards
      }
    } else{
      if (_expansionController.value > 0.1) {
        if (_expansionController.value > 0.9 / 2) {
          _expansionController.animateTo(1.0, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve);
        } else {
          _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve);
        }
      } else {
        if (_expansionController.value > 0.05) {
          _expansionController.animateTo(0.1, duration: Duration(milliseconds: getExpansionFlingDuration(true, flingVelocity)), curve: animationCurve);
        } else {
          _expansionController.animateTo(0.0, duration: Duration(milliseconds: getExpansionFlingDuration(false, flingVelocity)), curve: animationCurve);
        }
      }
    }
        //<-- or just continue to whichever edge is closer
  }
  final Curve animationCurve = Curves.easeOutCirc;
  final double maxAnimationDuration = 700.0;
  final double minAnimationDuration = 150.0;

  // Flingvelocity is the velocity which the user ends the fling with. Boolean true if the animation is going upwards, false if downwards
  int getExpansionFlingDuration(bool up, double flingVelocity){
    final double animationDuration = min(maxAnimationDuration, max(maxAnimationDuration / (flingVelocity.abs() * 0.10), minAnimationDuration));
    if (_expansionController.value > 0.1) {
      return up ? (animationDuration * (1 - 0.75 * (_expansionController.value - 0.1))).round() : (animationDuration * 1.5 * (_expansionController.value - 0.1)).round();
    } else {
      return up ? (animationDuration * (1 - 10 * (_expansionController.value))).round() : (animationDuration * 1.25 * (10 * _expansionController.value)).round();      
    }
  }
  bool isExpanded() => _expansionController.value >= 0.1;
  bool fullyExpanded() => _expansionController.value == 1.0;
  double getExpandedBarHeight(){
    return maxExpandedBarHeight * 0.1;
  }
  double maxExpandedBarHeight = 500.0; //Fallback value

  @override
  void initState() { 
    maxExpandedBarHeight = MediaQuery.of(context).size.height - 50.0; //Screen height minus the height of image controls bar
    _expansionController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 450),
    )..addListener((){
      widget.controller.expanded = isExpanded();
      widget.controller.fullyExpanded = fullyExpanded();
      setState(() {
        
      });
    });
    widget.controller.addListener((){
      if (widget.controller.expanded != isExpanded() || widget.controller.fullyExpanded != fullyExpanded()) {
        if (widget.controller.fullyExpanded) {
          _expansionController.animateTo(1.0, duration: Duration(milliseconds: 500), curve: animationCurve);
        } else if (widget.controller.expanded) {
          _expansionController.animateTo(0.1, duration: Duration(milliseconds: 500), curve: animationCurve);
        } else {
          _expansionController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: animationCurve);
        }
      }
    });
    super.initState();
  }
  @override
  void didUpdateWidget(AlbumControlsBar oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
       width: MediaQuery.of(context).size.width,
       child: GestureDetector(
         child: Column(children: <Widget>[
          getPreviewsBar(context),
          ImageControlsBar(submission: widget.controller.submission, controller: widget.controller, url: widget.controller.url,)
        ],),
        onVerticalDragUpdate: _handleExpandedDragUpdate,
        onVerticalDragEnd: _handleExpandedDragEnd,
       )
    );
  }

  ScrollController gridController = ScrollController();  
  Widget getPreviewsBar(BuildContext context){
    return Container(
      height: lerp(0, maxExpandedBarHeight),
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: <Widget> [
          AnimatedBuilder(
            animation: _expansionController,
            builder: (_, child){
              return Container(
                height: maxExpandedBarHeight * min(1 - _expansionController.value, 0.1),
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
                            child: Image(
                              height: double.infinity,
                              width: double.infinity,
                              color: Colors.black.withOpacity(i == widget.controller.currentIndex ? 0.38 : 0.0),
                              colorBlendMode: BlendMode.luminosity,
                              image: AdvancedNetworkImage(
                                url,
                                useDiskCache: true,
                                cacheRule: CacheRule(maxAge: Duration(days: 7))
                              ),
                              fit: BoxFit.cover,
                            ),
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
            },
          ),
          Container(
            height: maxExpandedBarHeight,
            color: Colors.black87,
            child: GridView.builder(
              controller: gridController,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (4).round()),
              itemCount: widget.controller.images.length,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, i){
                final url = widget.controller.images[i].thumbnailUrl;
                if (url != null && getLinkType(url) == LinkType.DirectImage){
                  return StatefulBuilder(builder: (context, child){
                    return InkWell(
                      child: Container(
                        margin: const EdgeInsets.all(3.0),
                        width: 125.0,
                        height: 125.0,
                        child: Image(
                          color: Colors.black.withOpacity(i == widget.controller.currentIndex ? 0.38 : 0.0),
                          colorBlendMode: BlendMode.luminosity,
                          width: double.infinity,
                          height: double.infinity,
                          image: AdvancedNetworkImage(
                            url,
                            useDiskCache: true,
                            cacheRule: const CacheRule(maxAge: const Duration(hours: 1))
                          ),
                          fit: BoxFit.cover,
                        )
                      ),
                      onTap: (){
                        setState(() {
                          widget.controller.setCurrentIndex(i);                
                          _reverseExpanded();
                        });
                      },
                    );
                  },);
                }
                return Container();
              },
            ),
          ),
        ]
        
      )
    );
  }
}

class ImageControlsBar extends StatelessWidget {
  final AlbumController controller;
  final Submission submission;
  final String url;
  ImageControlsBar({Key key, this.submission, this.url, this.controller} ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.0,
      width: MediaQuery.of(context).size.width,
      color: Colors.black.withOpacity(0.6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildCopyButton(context),
          _buildOpenUrlButton(context),
          submission != null ? _buildCommentsButton(context) : null, //Only show comment button if the parent usercontent is a submission (Because otherwise there wouldn't be any comments to show)
          _buildDownloadButton(context),
          _buildShareButton(context),
          controller != null ? _buildExpandButton(context) : null, //Only show expand button if the picture is a part of an album
        ].where((w) => notNull(w)).toList(),
      ),
    );
  }
  Widget _buildCopyButton(BuildContext context){
    return controller != null ?
      IconButton(
        icon: Icon(Icons.content_copy),
        color: Colors.white,
        onPressed: (){
          copyToClipboard(url).then((result){
            final snackBar = SnackBar(content: Text( result ? 'Copied Image Url to Clipboard' : "Failed to Copy Image Url to Clipboard"),);
            //Scaffold.of(context).showSnackBar(snackBar);
          });
        },
      )
      : PopupMenuButton<String>(
        child: Icon(Icons.content_copy),
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: selection_album,
            child: Text("Copy Album"),
          ),
          const PopupMenuItem<String>(
            value: selection_image,
            child: Text("Copy Image"),
          )
        ],
        onSelected: (String value) {
          if (value == selection_album) {
            copyToClipboard(url).then((result){
              final snackBar = SnackBar(content: Text( result ? 'Copied Album Url to Clipboard' : "Failed to Copy Album Url to Clipboard"),);
              //Scaffold.of(context).showSnackBar(snackBar);
            });
          } else {
            copyToClipboard(controller.currentImage().url).then((result){
              final snackBar = SnackBar(content: Text( result ? 'Copied Image Url to Clipboard' : "Failed to Copy Image Url to Clipboard"),);
              // ! Scaffold.of(context).showSnackBar(snackBar); NEEDS SCAFFOLD
            });
          }
        },
      );
  }
  Widget _buildOpenUrlButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.open_in_browser),
      color: Colors.white,
      onPressed: (){
        launchURL(context, url);
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
  Widget _buildExpandButton(BuildContext context){
    return IconButton(
      icon: Icon(Icons.grid_on),
      color: Colors.white,
      onPressed: (){
        controller.toggleExpand();
      },
    );
  }
  Widget _buildDownloadButton(BuildContext context){
    return controller != null ?
      IconButton(
        icon: Icon(Icons.file_download),
        color: Colors.white,
        onPressed: (){
          // TODO: Implement
        },
      )
      : PopupMenuButton<String>(
        child: Icon(Icons.file_download),
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: selection_album,
            child: Text("Download Album"),
          ),
          const PopupMenuItem<String>(
            value: selection_image,
            child: Text("Download Image"),
          )
        ],
        onSelected: (String value) {
          if (value == selection_album) {
            //TODO : IMPLEMENT
          } else {

          }
        },
      );
  }
  Widget _buildShareButton(BuildContext context){
    return controller != null ?
      IconButton(
        icon: Icon(Icons.share),
        color: Colors.white,
        onPressed: (){
          shareString(url);
        },
      )
      : PopupMenuButton<String>(
        child: Icon(Icons.share),
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: selection_album,
            child: Text("Share Album"),
          ),
          const PopupMenuItem<String>(
            value: selection_image,
            child: Text("Share Image"),
          )
        ],
        onSelected: (String value) {
          if (value == selection_album) {
            shareString(url);
          } else {
            shareString(controller.currentImage().url);
          }
        },
      );
  }
}