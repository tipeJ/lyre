import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'video_controls.dart';
import 'package:flutter/widgets.dart';
import 'package:lyre/UI/video_player/video_player.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

typedef Widget LyreVideoRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    _LyreVideoControllerProvider controllerProvider);

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. LyreVideo wraps it in a friendly skin to
/// make it easy to use!
class LyreVideo extends StatefulWidget {
  LyreVideo({
    Key key,
    this.controller,
  })  : assert(controller != null, 'You must provide a player controller'),
        super(key: key);

  /// The [LyreVideoController]
  final LyreVideoController controller;

  @override
  LyreVideoState createState() {
    return LyreVideoState();
  }
}

class LyreVideoState extends State<LyreVideo> {
  bool _isFullScreen = false;

  @override
  void didUpdateWidget(LyreVideo oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
  }

  void listener() async {
    if (widget.controller.isFullScreen && !_isFullScreen) {
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
    } else if (_isFullScreen) {
      Navigator.of(context).pop();
      _isFullScreen = false;
    }
  }

  Widget _buildFullScreenVideo(
      BuildContext context,
      Animation<double> animation,
      _LyreVideoControllerProvider controllerProvider) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      _LyreVideoControllerProvider controllerProvider) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    var controllerProvider = _LyreVideoControllerProvider(
      controller: widget.controller,
      child: LyreVideoPlayer(),
    );

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
          context, animation, secondaryAnimation, controllerProvider);
    }
    return widget.controller.routePageBuilder(
        context, animation, secondaryAnimation, controllerProvider);
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final TransitionRoute<Null> route = PageRouteBuilder<Null>(
      settings: RouteSettings(isInitialRoute: false),
      pageBuilder: _fullScreenRoutePageBuilder,
    );

    SystemChrome.setEnabledSystemUIOverlays([]);
    if (isAndroid) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (!widget.controller.allowedScreenSleep) {
      Screen.keepOn(true);
    }

    await Navigator.of(context).push(route);
    _isFullScreen = false;
    widget.controller.exitFullScreen();

    bool isKeptOn = await Screen.isKeptOn;
    if (isKeptOn) {
      Screen.keepOn(false);
    }

    SystemChrome.setEnabledSystemUIOverlays(
        widget.controller.systemOverlaysAfterFullScreen);
    SystemChrome.setPreferredOrientations(
        widget.controller.deviceOrientationsAfterFullScreen);
  }

  @override
  Widget build(BuildContext context) {
    return _LyreVideoControllerProvider(
      controller: widget.controller,
      child: LyreVideoPlayer(),
    );
  }
}

/// The LyreVideoController is used to configure and drive the LyreVideo Player
/// Widgets. It provides methods to control playback, such as [pause] and
/// [play], as well as methods that control the visual appearance of the player,
/// such as [enterFullScreen] or [exitFullScreen].
///
/// In addition, you can listen to the LyreVideoController for presentational
/// changes, such as entering and exiting full screen mode. To listen for
/// changes to the playback, such as a change to the seek position of the
/// player, please use the standard information provided by the
/// `VideoPlayerController`.
class LyreVideoController extends ChangeNotifier {
  LyreVideoController({
    this.videoPlayerController,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showControls = true,
    this.customControls,
    this.errorBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
    this.routePageBuilder = null,
  }) : assert(videoPlayerController != null,
            'You must provide a controller to play a video') {
    _initialize();
  }

  /// Defines if the player will sleep in fullscreen or not
  final bool allowedScreenSleep;

  /// Defines if the fullscreen control should be shown
  final bool allowFullScreen;

  /// Defines if the mute control should be shown
  final bool allowMuting;

  /// The Aspect Ratio of the Video. Important to get the correct size of the
  /// video!
  ///
  /// Will fallback to fitting within the space allowed.
  final double aspectRatio;

  /// Initialize the Video on Startup. This will prep the video for playback.
  final bool autoInitialize;

  /// Play the video as soon as it's displayed
  final bool autoPlay;

  /// Defines customised controls. Check [MaterialControls] or
  /// [CupertinoControls] for reference.
  final Widget customControls;

  /// Defines the set of allowed device orientations after exiting fullscreen
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;

  /// Defines if the player will start in fullscreen when play is pressed
  final bool fullScreenByDefault;

  /// Defines if the controls should be for live stream video
  final bool isLive;

  /// Whether or not the video should loop
  final bool looping;

  /// A widget which is placed between the video and the controls
  final Widget overlay;

  /// The placeholder is displayed underneath the Video before it is initialized
  /// or played.
  final Widget placeholder;

  /// Defines a custom RoutePageBuilder for the fullscreen
  final LyreVideoRoutePageBuilder routePageBuilder;


  /// Whether or not to show the controls at all
  final bool showControls;

  /// Weather or not to show the controls when initializing the widget.
  final bool showControlsOnInitialize;

  /// Start video at a certain position
  final Duration startAt;

  /// Defines the system overlays visible after exiting fullscreen
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;

  /// The controller for the video you want to play
  final VideoPlayerController videoPlayerController;

  bool _isFullScreen = false;

  /// When the video playback runs  into an error, you can build a custom
  /// error message.
  final Widget Function(BuildContext context, String errorMessage) errorBuilder;

  static LyreVideoController of(BuildContext context) {
    final lyreControllerProvider =
        context.inheritFromWidgetOfExactType(_LyreVideoControllerProvider)
            as _LyreVideoControllerProvider;

    return lyreControllerProvider.controller;
  }

  bool get isFullScreen => _isFullScreen;

  Future _initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.initialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }

      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  void _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }
  bool expanded = false;

  void toggleZoom(){
    expanded = !expanded;
    notifyListeners();
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }
}

class _LyreVideoControllerProvider extends InheritedWidget {
  const _LyreVideoControllerProvider({
    Key key,
    @required this.controller,
    @required Widget child,
  })  : assert(controller != null),
        assert(child != null),
        super(key: key, child: child);

  final LyreVideoController controller;

  @override
  bool updateShouldNotify(_LyreVideoControllerProvider old) =>
      controller != old.controller;
}
