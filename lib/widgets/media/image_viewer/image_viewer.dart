import 'dart:math';
import 'dart:ui' as prefix0;

import 'package:draw/draw.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Models/image.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/bloc/lyre_bloc.dart';
import 'package:lyre/UploadUtils/ImgurAPI.dart';
import 'package:lyre/utils/share_utils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

const selection_image = "Image";
const selection_album = "Album";

///Class for viewing both single images and Albums
class ImageViewer extends StatefulWidget {
  //Submission which contains methods for opening comments, etc (optional)
  Submission submission;
  LinkType linkType;
  ///The Url for the image/album
  String url;

  ImageViewer(String url, [Submission submission]){
    this.url = url;
    linkType = getLinkType(url);
    if (submission != null){
      this.submission = submission;
    }
  }

  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  AlbumController _albumController;

  @override 
  void dispose() {
    _albumController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (albumLinkTypes.contains(widget.linkType)){
      if (_albumController != null) return _buildAlbumStack();
      return FutureBuilder(
        future: ImgurAPI().getAlbumPictures(widget.url, qualityKey: BlocProvider.of<LyreBloc>(context).state.imgurThumbnailQuality),
        builder: (context, AsyncSnapshot<List<LyreImage>> snapshot){
          if (snapshot.hasData){
            _albumController = AlbumController(snapshot.data, widget.submission, widget.url);
            return _buildAlbumStack();
          } else {
            return const Center(child: const CircularProgressIndicator(),);
          }
        },
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget> [
        SingleImageViewer(widget.url),
        Positioned(
          bottom: 0.0,
          child: ImageControlsBar(submission: widget.submission, url: widget.url, isAlbum: false,),
        )
      ]
    );
  }

  Widget _buildAlbumStack() {
    return _AlbumControllerProvider(
      controller: _albumController,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AlbumViewer(),
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              child: SafeArea(child: CurrentImageIndicator(),),
              margin: EdgeInsets.only(top: 15.0),
            ),
          ),
          Positioned(
            bottom: 0.0,
            child: AlbumControlsBar(),
          )
        ],
      ),
    );
  }
}

class CurrentImageIndicator extends StatefulWidget {
  const CurrentImageIndicator({
    Key key,
  }) : super(key: key);

  @override
  _CurrentImageIndicatorState createState() => _CurrentImageIndicatorState();
}

class _CurrentImageIndicatorState extends State<CurrentImageIndicator> {

  AlbumController _albumController;
  int currentIndex = 0;
  
  void _updateIndicator(){
    if (_albumController.currentIndex != currentIndex) {
      setState(() { 
        currentIndex = _albumController.currentIndex;
      });
    }
  }
  @override
  void dispose() { 
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    _albumController = AlbumController.of(context);
    _albumController.addListener(_updateIndicator);
    return Material(color: Colors.transparent, child: Text(
      (currentIndex + 1).toString() + '/' + _albumController.images.length.toString(),
      style: TextStyle(
        fontSize: 26.0
      ),
    ),);
  }
}

///Class for controlling Album behaviour in image_viewer
class AlbumController extends ChangeNotifier{
  List<LyreImage> images;
  String url;
  Submission submission;
  int currentIndex = 0;

  bool expanded = false;
  bool fullyExpanded = false;

  AlbumController(this.images, this.submission, this.url, [currentIndex]);

  static AlbumController of(BuildContext context) {
    final lyreControllerProvider =
        context.inheritFromWidgetOfExactType(_AlbumControllerProvider)
            as _AlbumControllerProvider;

    return lyreControllerProvider.controller;
  }

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
  void closeExpanded(){
    if (fullyExpanded){
      fullyExpanded = false;
      expanded = false;
      notifyListeners();
    }
  }
}
class _AlbumControllerProvider extends InheritedWidget {
  const _AlbumControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final AlbumController controller;

  @override
  bool updateShouldNotify(_AlbumControllerProvider old) =>
      controller != old.controller;
}

///Class that contains the necessary widgets for displaying Album images and galleries.
class AlbumViewer extends StatefulWidget {
  AlbumViewer({Key key}) : super(key: key);

  _AlbumViewerState createState() => _AlbumViewerState();
}

class _AlbumViewerState extends State<AlbumViewer> {
  final pageController = PageController();
  AlbumController _albumController;

  void _pageListener(){
    if (_albumController.currentIndex != pageController.page.round()) _albumController.setCurrentIndex(pageController.page.round());
  }

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override void dispose(){
    pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ScrollController _scrollController;

  @override
  Widget build(BuildContext context) {
    _albumController = AlbumController.of(context);
    _albumController.addListener((){
      if (pageController.page.round() != _albumController.currentIndex){
        setState(() {
          pageController.jumpToPage(_albumController.currentIndex);
        });
      }
    });
    pageController.addListener(_pageListener);
    return PhotoViewGallery.builder(
      pageController: pageController,
      itemCount: _albumController.images.length,
      builder: (context, i){
        final image = _albumController.images[i].url;
        switch (getLinkType(image)) {
          case LinkType.DirectImage:
            return PhotoViewGalleryPageOptions(
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered,
              initialScale: PhotoViewComputedScale.contained,
              imageProvider: AdvancedNetworkImage(
                image,
                useDiskCache: true,
                cacheRule: const CacheRule(maxAge: const Duration(minutes: 40))
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
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered,
      initialScale: PhotoViewComputedScale.contained,
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
  ///The minimum height for the horizontal previewsBar. Will get one-tenths of gallery height if it's larger that way.
  final double minimumHeight;

  const AlbumControlsBar({Key key, this.minimumHeight = 75.00}) : super(key: key);

  _AlbumControlsBarState createState() => _AlbumControlsBarState();
}

class _AlbumControlsBarState extends State<AlbumControlsBar> with SingleTickerProviderStateMixin{
  AnimationController _expansionController;
  AlbumController _albumController;

  double lerp(double min, double max) => prefix0.lerpDouble(min, max, _expansionController.value);

  void _handleExpandedDragUpdate(DragUpdateDetails details) {
    if(_expansionController.value == 1 && ((_gridController.offset == 0.0 && details.delta.dy < 0.0) || _gridController.offset != 0.0)){
      _gridController.jumpTo(_gridController.offset - details.delta.dy);
    } else {
      _expansionController.value -= details.primaryDelta /
      _maxExpandedBarHeight; //<-- Update the _expansionController.value by the movement done by user.
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
        getExpandedBarHeight; //<-- calculate the velocity of the gesture
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
  final Curve animationCurve = Curves.easeOut;
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
  double get getExpandedBarHeight => min(_maxExpandedBarHeight * 0.1, 125);
  double _maxExpandedBarHeight = 500.0; //Fallback value

  @override
  void didUpdateWidget(AlbumControlsBar oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() { 
    _expansionController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: Duration(milliseconds: 450),
    )..addListener((){
      _albumController.expanded = isExpanded();
      _albumController.fullyExpanded = fullyExpanded();
      setState(() {
        
      });
    });
    _gridController = ScrollController();
    _gridController.addListener(() {
      if (_gridController.offset < 0.0) {
        setState(() {
         _popIndicatorOpacity = min(1.0, -_gridController.offset / (_maxExpandedBarHeight / 6)); 
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() { 
    _expansionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _albumController = AlbumController.of(context);
    _maxExpandedBarHeight = MediaQuery.of(context).size.height - 0; //Screen height minus the height of image controls bar
    _albumController.addListener((){
      if (_albumController.expanded != isExpanded() || _albumController.fullyExpanded != fullyExpanded()) {
        if (_albumController.fullyExpanded) {
          _expansionController.animateTo(1.0, duration: Duration(milliseconds: 500), curve: animationCurve);
        } else if (_albumController.expanded) {
          _expansionController.animateTo(0.1, duration: Duration(milliseconds: 500), curve: animationCurve);
        } else {
          _expansionController.animateTo(0.0, duration: Duration(milliseconds: 500), curve: animationCurve);
        }
      }
    });
    return Container(
       width: MediaQuery.of(context).size.width,
       child: GestureDetector(
         child: Column(children: <Widget>[
          getPreviewsBar(context),
          ImageControlsBar(submission: _albumController.submission, url: _albumController.url, isAlbum: true,)
        ],),
        onVerticalDragUpdate: _handleExpandedDragUpdate,
        onVerticalDragEnd: _handleExpandedDragEnd,
       )
    );
  }
  double _popIndicatorOpacity = 0.0;

  ScrollController _gridController;  
  Widget getPreviewsBar(BuildContext context){
    final preferredColumnAmount = MediaQuery.of(context).orientation == Orientation.portrait ? BlocProvider.of<LyreBloc>(context).state.albumColumnPortrait : BlocProvider.of<LyreBloc>(context).state.albumColumnLandscape;
    final int columnCount = preferredColumnAmount ?? max(3, (MediaQuery.of(context).size.width / 125.0).floor()); //The amount of columns in gallery. Minimum is 3. Can be overridden by user.
    return Container(
      height: _maxExpandedBarHeight,
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget> [
         Container(
            //Height of horizontal-scrolling previewsBar
            height: min((_expansionController.value * 10) * max(_maxExpandedBarHeight * 0.1, widget.minimumHeight), (1.1-(_expansionController.value * _expansionController.value+0.1)) * max(_maxExpandedBarHeight * 0.1, widget.minimumHeight)),//min(_maxExpandedBarHeight * min(1 - _expansionController.value, 0.1), _expansionController.value * _maxExpandedBarHeight),
            child: ListView.builder(
              itemCount: _albumController.images.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i){
                final url = _albumController.images[i].thumbnailUrl;
                if (url != null && getLinkType(url) == LinkType.DirectImage){
                  return StatefulBuilder(builder: (context, child){
                    return GestureDetector(
                      child: PreviewImage(url: url, index: i, size: Size(75.0, getExpandedBarHeight)),                      
                      onTap: (){
                        setState(() {
                          _albumController.setCurrentIndex(i);                
                        });
                      },
                    );
                  },);
                }
                return Container();
              },
            ),
          ),
          Container(
            //Height of gallery
            height: max((_expansionController.value - 0.1) * _maxExpandedBarHeight, 0.0),
            //Color that overlays the pageview underneath.
            color: Colors.black87,
            //Listens for scroll end events. if the indicator opacity is high enough, reverse the animation.
            child: Listener(
              onPointerUp: (PointerUpEvent event) {
                  if (_popIndicatorOpacity > 0.9) {
                    _albumController.closeExpanded();
                  }
                return true;
              },
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: Opacity(
                        opacity: _popIndicatorOpacity,
                        child: const Icon(Icons.arrow_downward, size: 45.0,),
                      ),
                    ),
                  ),
                  GridView.builder(
                    controller: _gridController,
                    physics: BouncingScrollPhysics(),
                    gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columnCount),
                    itemCount: _albumController.images.length,
                    scrollDirection: Axis.vertical,
                    itemBuilder: (context, i){
                      final url = _albumController.images[i].thumbnailUrl;
                      if (url != null && getLinkType(url) == LinkType.DirectImage){
                        return GestureDetector(
                          child: new PreviewImage(url: url, index: i, size: Size(125.0, 125.0),),
                          onTap: (){
                            setState(() {
                              _albumController.setCurrentIndex(i);                
                              _reverseExpanded();
                            });
                          },
                        );
                      }
                      //Empty widget in case of error
                      return Container();
                    },
                  ),
                ],
              ),
            ),
          ),
        ]
      )
    );
  }
}

//Class for showing Thumbnail images, with lower quality than the full-size ones and with an indicator for selected image.
class PreviewImage extends StatefulWidget {
  const PreviewImage({
    Key key,
    @required this.url,
    @required this.index,
    @required this.size,
  }) : super(key: key);

  final String url;
  final int index;
  final Size size;

  @override
  _PreviewImageState createState() => _PreviewImageState();
}

class _PreviewImageState extends State<PreviewImage> {
  AlbumController _albumController;

  void _updateCurrentIndex(){
    if (selected != (_albumController.currentIndex == widget.index)) {
      setState(() {
        selected = !selected;
      });
    }
  }

  bool selected = false;

  @override
  Widget build(BuildContext context) {
    _albumController = AlbumController.of(context);
    if (_albumController.currentIndex == widget.index) selected = true;
    _albumController.addListener(_updateCurrentIndex);
    return Container(
      margin: const EdgeInsets.all(3.0),
      width: widget.size.width,
      height: widget.size.height,
      child: Image(
        color: Colors.black.withOpacity(widget.index == _albumController.currentIndex ? 0.38 : 0.0),
        colorBlendMode: BlendMode.luminosity,
        width: double.infinity,
        height: double.infinity,
        image: AdvancedNetworkImage(
          widget.url,
          useDiskCache: false,
          cacheRule: const CacheRule(maxAge: const Duration(hours: 1))
        ),
        fit: BoxFit.cover,
      )
    );
  }
}

class ImageControlsBar extends StatelessWidget {
  AlbumController _albumController;
  final bool isAlbum;
  final Submission submission;
  final String url;

  ImageControlsBar({Key key, this.submission, this.url, this.isAlbum} ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    _albumController = isAlbum ? AlbumController.of(context) : null;
    return Material(
      color: Colors.black.withOpacity(0.6),
      child: Container(
        height: 50.0,
        width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildCopyButton(context),
            _buildOpenUrlButton(context),
            submission != null ? _buildCommentsButton(context) : null, //Only show comment button if the parent usercontent is a submission (Because otherwise there wouldn't be any comments to show)
            _buildDownloadButton(context),
            _buildImageSearchButton(context),
            _buildShareButton(context),
            _albumController != null ? _buildExpandButton(context) : null, //Only show expand button if the picture is a part of an album
          ].where((w) => notNull(w)).toList(),
        ),
      )
    );
  }
  Widget _buildCopyButton(BuildContext context){
    return _albumController == null ?
      IconButton(
        icon: const Icon(Icons.content_copy),
        tooltip: "Copy Image URL",
        onPressed: (){
          copyToClipboard(url).then((result){
            final snackBar = SnackBar(content: Text( result ? 'Copied Image Url to Clipboard' : "Failed to Copy Image Url to Clipboard"));
            Scaffold.of(context).showSnackBar(snackBar);
          });
        },
      )
      : PopupMenuButton<String>(
        child: const Icon(Icons.content_copy),
        tooltip: "Copy Album or Image URL",
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: selection_album,
            child: Text("Copy Album URL"),
          ),
          const PopupMenuItem<String>(
            value: selection_image,
            child: Text("Copy Image URL"),
          )
        ],
        onSelected: (String value) {
          if (value == selection_album) {
            copyToClipboard(url).then((result){
              final snackBar = SnackBar(content: Text( result ? 'Copied Album Url to Clipboard' : "Failed to Copy Album Url to Clipboard"),);
              Scaffold.of(context).showSnackBar(snackBar);
            });
          } else {
            copyToClipboard(_albumController.currentImage().url).then((result){
              final snackBar = SnackBar(content: Text( result ? 'Copied Image Url to Clipboard' : "Failed to Copy Image Url to Clipboard"),);
              Scaffold.of(context).showSnackBar(snackBar);
            });
          }
        },
      );
  }

  ///Button which opens the image/album in external browser
  Widget _buildOpenUrlButton(BuildContext context){
    return IconButton(
      icon: const Icon(Icons.open_in_browser),
      tooltip: "Open in Browser",
      onPressed: (){
        launchURL(context, url);
      },
    );
  }
  ///Button which opens comments for the image. Only appears when a submission has been assigned to the image_viewer
  Widget _buildCommentsButton(BuildContext context){
    return IconButton(
      icon: const Icon(Icons.comment),
      tooltip: "Open Comments",
      onPressed: (){
        Navigator.of(context).pushNamed('comments', arguments: submission);
      },
    );
  }
  ///Button which toggles the gallery expand state
  Widget _buildExpandButton(BuildContext context){
    return IconButton(
      icon: const Icon(Icons.grid_on),
      tooltip: "Open Album View",
      onPressed: (){
        _albumController.toggleExpand();
      },
    );
  }
  ///Button which is used to download images/albums
  Widget _buildDownloadButton(BuildContext context){
    return _albumController == null ?
      IconButton(
        icon: const Icon(Icons.file_download),
        tooltip: "Download Image",
        onPressed: (){
          // TODO: Implement
        },
      )
      : PopupMenuButton<String>(
        child: const Icon(Icons.file_download),
        tooltip: "Download Album",
        itemBuilder: (context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: selection_album,
            child: const Text("Download Album"),
          ),
          const PopupMenuItem<String>(
            value: selection_image,
            child: const Text("Download Image"),
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

  ///Google image search for similar images to the one selected
  IconButton _buildImageSearchButton(BuildContext context){
    return IconButton(
      icon: const Icon(MdiIcons.imageSearch),
      tooltip: "Search for similar images",
      onPressed: () => launchURL(context, GOOGLE_IMAGE_SEARCH_BASE_URL + url),
    );
  }
  ///Button which is used to share the image/album
  Widget _buildShareButton(BuildContext context){
    return _albumController == null ?
      IconButton(
        icon: const Icon(Icons.share),
        tooltip: "Share Image",
        onPressed: (){
          shareString(url);
        },
      )
      : PopupMenuButton<String>(
        child: const Icon(Icons.share),
        tooltip: "Share Album",
        itemBuilder: (context) => [
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
            shareString(_albumController.currentImage().url);
          }
        },
      );
  }
}