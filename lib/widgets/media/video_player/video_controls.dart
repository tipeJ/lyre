import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lyre/Models/models.dart';
import 'package:lyre/Resources/resources.dart';
import 'package:lyre/utils/utils.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'progress_bar.dart';
import 'package:video_player/video_player.dart';
import 'lyre_video_player.dart';

class MaterialControls extends StatefulWidget {
  const MaterialControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> with SingleTickerProviderStateMixin{
  VideoPlayerValue _latestValue;
  double _latestVolume;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  static const buttonPadding = 20.0;
  static const expandedBarHeight = 48.0;

  AnimationController _expansionController;
  bool isExpanded = false;
  

  double lerp(double min, double max) => lerpDouble(min, max, _expansionController.value);

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

  static const barHeight = 48.0;

  VideoPlayerController controller;
  LyreVideoController lyreVideoController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return lyreVideoController.errorBuilder != null
          ? lyreVideoController.errorBuilder(
              context,
              lyreVideoController.videoPlayerController.value.errorDescription,
            )
          : const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 42,
              ),
            );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: Column(
          children: <Widget>[
            _latestValue != null &&
                        !_latestValue.isPlaying &&
                        _latestValue.duration == null ||
                    _latestValue.isBuffering
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildHitArea(),
            GestureDetector(
              child: Column(children: <Widget>[
                _buildBottomBar(context),
                _buildBottomExpandingBar(context)
              ],),
              onVerticalDragUpdate: _handleExpandedDragUpdate,
              onVerticalDragEnd: _handleExpandedDragEnd,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void initState() { 
    _expansionController = AnimationController(
      //<-- initialize a controller
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener((){
      setState(() { 
      });
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    final _oldController = lyreVideoController;
    lyreVideoController = LyreVideoController.of(context);
    controller = lyreVideoController.videoPlayerController;

    if (_oldController != lyreVideoController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  Material _buildBottomBar(
    BuildContext context,
  ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return Material(
      color: Colors.black54,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: buttonPadding),
        height: barHeight,
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            lyreVideoController.isLive
                ? const Expanded(child: Text('LIVE'))
                : _buildPosition(iconColor),
            lyreVideoController.isLive ? const SizedBox() : _buildProgressBar(),
            lyreVideoController.allowMuting
                ? _buildMuteButton(controller)
                : Container(),
            _buildZoomButton(),
            lyreVideoController.allowFullScreen
                ? _buildExpandButton()
                : Container(),
          ],
        ),
      )
    );
  }
  Container _buildBottomExpandingBar(
    BuildContext context,
  ) {
    return Container(
      height: lerp(0, barHeight),
      color: Colors.black.withOpacity(0.5),
      child: Padding(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            !lyreVideoController.isSingleFormat ? _buildQualityButton(context) : const SizedBox(),
            // Row(children: <Widget>[
            //   _buildSlowerButton(),
            //   _buildPlayBackSpeedIndicator(),
            //   _buildFasterButton()
            // ]),
            _buildShareButton
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: buttonPadding),
      )
    );
  }

  PopupMenuButton _buildQualityButton(BuildContext context) => PopupMenuButton<LyreVideoFormat>(
    child: Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 5.0),
          child: Icon(Icons.settings)
        ),
        Text(lyreVideoController.currentFormat.height.toString())
      ]
    ),
    initialValue: lyreVideoController.currentFormat,
    itemBuilder: (_) => List<PopupMenuItem<LyreVideoFormat>>.generate(
      lyreVideoController.formats.length, 
      (i) => PopupMenuItem<LyreVideoFormat>(
        value: lyreVideoController.formats[i],
        child: Text(lyreVideoController.formats[i].height.toString()),
      )
    ),
    onSelected: (format) {
      LyreVideoController.of(context).changeFormat(lyreVideoController.formats.indexOf(format)).then((_){
        lyreVideoController = LyreVideoController.of(context);
        controller = lyreVideoController.videoPlayerController;
        _dispose();
        _initialize().then((_){
        });
      });
    },
  );

  /// Widget which shows current playback speed
  Container _buildPlayBackSpeedIndicator(){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: buttonPadding),
      child: const Material(
        child: Text(
          "1.0" // ? NOT YET SUPPORTED BY VIDEO_PLAYER
        ),
      )
    );
  }

  /// Button to slow playback speed
  GestureDetector _buildSlowerButton() {
    return GestureDetector(
      onTap: _playSlower,
      child: Container(
        height: barHeight,
        child: const Center(
          child: Icon(Icons.fast_rewind)
        ),
      ),
    );
  }

  /// Button to raising playback speed
  GestureDetector _buildFasterButton() {
    return GestureDetector(
      onTap: _playFaster,
      child: Container(
        height: barHeight,
        child: const Center(
          child: Icon(Icons.fast_forward)
        ),
      ),
    );
  }

  void _playSlower(){
    // ? NOT YET SUPPORTED BY VIDEO_PLAYER
  }
  void _playFaster(){
    // ? NOT YET SUPPORTED BY VIDEO_PLAYER
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: Container(
        height: barHeight,
        child: Center(
          child: Icon(
            lyreVideoController.isFullScreen
                ? Icons.fullscreen_exit
                : Icons.fullscreen,
          ),
        ),
      ),
    );
  }

  GestureDetector _buildZoomButton() {
    return GestureDetector(
      onTap: _onZoomToggle,
      child: Container(
        height: barHeight,
        margin: EdgeInsets.only(right: buttonPadding),
        child: Center(
          child: Icon(
            lyreVideoController.expanded
                ? Icons.zoom_out
                : Icons.zoom_in,
          ),
        ),
      ),
    );
  }

  IconButton get _buildShareButton => IconButton(
    icon: const Icon(Icons.share),
    onPressed: () {
      shareString(lyreVideoController.sourceUrl);
    },
  );
  

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          //Expandedigator.of(context).maybePop();
        },
        child: Container(),
      ),
    );
  }

  GestureDetector _buildMuteButton(
    VideoPlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: ClipRect(
        child: Container(
          child: Container(
            margin: EdgeInsets.only(right: buttonPadding),
            height: barHeight,
            child: Icon(
              (_latestValue != null && _latestValue.volume > 0)
                  ? Icons.volume_up
                  : Icons.volume_off,
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(right: buttonPadding),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: const TextStyle(
          fontSize: 14.0,
        ),
      )
    );
  }

  static String formatDuration(Duration position) {
    final ms = position.inMilliseconds;

    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    var minutes = seconds ~/ 60;
    seconds = seconds % 60;

    final hoursString = hours >= 10 ? '$hours' : hours == 0 ? '00' : '0$hours';

    final minutesString =
        minutes >= 10 ? '$minutes' : minutes == 0 ? '00' : '0$minutes';

    final secondsString =
        seconds >= 10 ? '$seconds' : seconds == 0 ? '00' : '0$seconds';

    final formattedTime =
        '${hoursString == '00' ? '' : hoursString + ':'}$minutesString:$secondsString';

    return formattedTime;
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        lyreVideoController.autoPlay) {
      _startHideTimer();
    }

    if (lyreVideoController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      lyreVideoController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _onZoomToggle() {
    setState(() {
      lyreVideoController.toggleZoom();
    });
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(const Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 20.0),
        child: LyreVideoProgressBar(
          controller,
          onDragStart: () {
            setState(() {
              _dragging = true;
            });

            _hideTimer?.cancel();
          },
          onDragEnd: () {
            setState(() {
              _dragging = false;
            });

            _startHideTimer();
          },
        ),
      ),
    );
  }
}
