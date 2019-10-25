import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Resources/gfycat_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/UI/Router.dart';
import 'package:lyre/UI/image_viewer/image_viewer.dart';
import 'package:lyre/UI/interfaces/previewCallback.dart';
import 'package:lyre/UI/interfaces/previewc.dart';
import 'package:lyre/UI/video_player/lyre_video_player.dart';
import 'package:lyre/utils/twitchUtils.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

enum PreviewType { Image, Video }

class App extends StatelessWidget{
  Widget _buildWithTheme(BuildContext context, ThemeState themeState){
    return MaterialApp(
      title: 'Lyre',
      theme: themeState.themeData,
      home: LyreApp(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, AsyncSnapshot<SharedPreferences> snapshot){
        if(snapshot.hasData){
          final prefs = snapshot.data;
          return BlocProvider(
            builder: (context) => ThemeBloc(prefs.get('currentTheme') == null ? "" : prefs.get('currentTheme')),
            child: BlocBuilder<ThemeBloc, ThemeState>(
              builder: _buildWithTheme,
            ),
          );
        }else{
          return Container(
            width: 25.0,
            height: 25.0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
class LyreApp extends StatefulWidget {
  @override
  _LyreAppState createState() => _LyreAppState();
}

class _LyreAppState extends State<LyreApp> with PreviewCallback{
  _LyreAppState(){
    PreviewCall().callback = this;
  }

  OverlayEntry imageEntry;
  bool isPreviewing = false;
  OverlayState overlayState;
  var previewUrl = "https://i.imgur.com/CSS40QN.jpg";
  PreviewType previewType;

  OverlayEntry videoEntry;

  LyreVideoController _vController;
  VideoPlayerController _videoController;
  Future<void> _videoInitialized;

  @override
  void initState(){

    overlayState = Overlay.of(context);
    imageEntry = OverlayEntry(
        builder: (context) => new Container(
          width: 400.0,
          height: 500.0,
          child: new Container(
            child: ImageViewer(previewUrl),
            color: Color.fromARGB(200, 0, 0, 0),
          )
        ),
    );
    videoEntry = OverlayEntry(
      builder: (context) => Container(
        color: const Color.fromARGB(200, 0, 0, 0),
        child: StatefulBuilder(
          builder: (context, setState){
            return FutureBuilder(
              future: _videoInitialized,
              builder: (context, snapshot){
                if (snapshot.connectionState == ConnectionState.done){
                  return LyreVideo(
                    controller: _vController,
                  );
                } else {
                  return const Center(child: CircularProgressIndicator(),);
                }
              },
            );
          },
          ),
        ),
      );
    super.initState();
  }

  @override
  void preview(String url) {
    final linkType = getLinkType(url);
    if (linkType == LinkType.DirectImage || albumLinkTypes.contains(linkType)){
      if(!isPreviewing){
        previewType = PreviewType.Image;
        previewUrl = url.toString();
        showOverlay();
      }
    } else if (videoLinkTypes.contains(linkType)){
      if (!isPreviewing) {
        previewType = PreviewType.Video;
        handleVideoLink(linkType, url);
      }
    }
  }

  @override
  void previewEnd() {
    if (isPreviewing) {
      previewUrl = "";
      // previewController.reverse();
      hideOverlay();
    }
  }

  @override
  void view(String url) {}

  showOverlay() {
    if (!isPreviewing) {
      overlayState.insert(imageEntry);
      isPreviewing = true;
    }
  }

  showVideoOverlay() {
    if (!isPreviewing) {
      overlayState.insert(videoEntry);
      isPreviewing = true;
    }
  }

  void handleVideoLink(LinkType linkType, String url) async {
    if (linkType == LinkType.Gfycat){
      gfycatProvider().getGfyWebmUrl(getGfyid(url)).then((videoUrl) {
        _videoInitialized = _initializeVideo(videoUrl);
      });
    } else if (linkType == LinkType.RedditVideo){
      _videoInitialized = _initializeVideo(url, VideoFormat.dash);
    } else if (linkType == LinkType.TwitchClip){
      final clipVideoUrl = await getTwitchClipVideoLink(url);
      _videoInitialized = _initializeVideo(clipVideoUrl);
    }
  }

  Future<void> _initializeVideo(String videoUrl, [VideoFormat format]) async {
    
    _videoController = VideoPlayerController.network(videoUrl, formatHint: format);
    showVideoOverlay();
    await _videoController.initialize();
    _vController = LyreVideoController(
      showControls: true,
      aspectRatio: _videoController.value.aspectRatio,
      autoPlay: true,
      videoPlayerController: _videoController,
      looping: true,
      placeholder: CircularProgressIndicator(),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  hideOverlay() {
    if (isPreviewing) {
      if (previewType == PreviewType.Image) {
        imageEntry.remove();
      } else if (previewType == PreviewType.Video) {
        //_videoController.pause();
        videoEntry.remove();
      }
      overlayState.deactivate();
      isPreviewing = false;
    }
  }

  @override
  Future<bool> canPop() async {
    if(isPreviewing){
      if (_vController != null && _vController.isFullScreen){
        _vController.exitFullScreen();
      } else {
        previewUrl = "";
        hideOverlay();
      }
      return false;
    }
    return !await PreviewCall().navigatorKey.currentState.maybePop();
  }

  @override
  void dispose() {
    overlayState.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
    builder: (context, constraints) {
      return WillPopScope(
        onWillPop: canPop,
        child: Navigator(
          key: PreviewCall().navigatorKey,
          initialRoute: 'posts',
          onGenerateRoute: Router.generateRoute,
        ),
      );
    },
    );
  }
}