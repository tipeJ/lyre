import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_player.dart';
import 'package:lyre/widgets/media/video_player/lyre_video_progress_bar.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

class LyreMaterialVideoControls extends StatefulWidget {
  final Widget trailing;

  LyreMaterialVideoControls({this.trailing = const SizedBox(), Key key}) : super(key: key);

  @override
  _LyreMaterialVideoControlsState createState() => _LyreMaterialVideoControlsState();
}

class _LyreMaterialVideoControlsState extends State<LyreMaterialVideoControls> {
  static const int _skipAmount = 5;

  bool _controlsVisible = false;

  VideoPlayerValue _latestValue;
  Timer _hideTimer;
  Timer _initTimer;

  VideoPlayerController controller;
  LyreVideoController lyreVideoController;

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
  
  void _dispose() {
    controller.removeListener(_updateState);
    // _hideTimer?.cancel();
    // _initTimer?.cancel();
    // _showAfterExpandCollapseTimer?.cancel();
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        lyreVideoController.autoPlay) {
      _startHideTimer();
    }

    if (lyreVideoController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
      });
    }
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  void _handleVolumeDrag(double amount) {
    final vol = controller.value.volume;
    final nextV = vol + amount;
    controller.setVolume(nextV);
  }

  void _handleBrightnessDrag(double amount) async {
    double brightness = await Screen.brightness;
    Screen.setBrightness(brightness + amount);
  }

  void _skip(int amount) {
    Duration currentPosition = _latestValue.position;
    controller.seekTo(Duration(seconds: currentPosition.inSeconds + amount));
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideTimer?.cancel();
        controller.pause();
      } else {
        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _height = MediaQuery.of(context).size.height;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _controlsVisible ? 1.0 : 0.0,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topCenter,
                    child: SafeArea(
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.ac_unit),
                          const Icon(Icons.ac_unit),
                          const Icon(Icons.ac_unit),
                          const Spacer(),
                          widget.trailing
                        ],
                      )
                    ),
                  ),
                  Positioned(
                    bottom: 25.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(_formatDuration(_latestValue.position)),
                          Text(_formatDuration(_latestValue.duration)),
                        ],
                      )
                    )
                  ),
                  Row(
                    children: <Widget>[
                      Flexible(
                        flex: 5,
                        child: GestureDetector(
                          onDoubleTap: () {
                            _skip(-_skipAmount);
                          },
                          onTap: () {
                            setState(() {
                              _controlsVisible = !_controlsVisible;
                              if (_controlsVisible) {
                                _hideTimer?.cancel();
                                _startHideTimer();
                              }
                            });
                          },
                          onVerticalDragUpdate: (details) {
                            final value = -details.delta.dy / (_height / 4.5);
                            _handleVolumeDrag(value);
                          },
                        )
                      ),
                      Flexible(
                        flex: 3,
                        child: GestureDetector(
                          onDoubleTap: _playPause,
                          onTap: () {
                            setState(() {
                              _controlsVisible = !_controlsVisible;
                              if (_controlsVisible) {
                                _hideTimer?.cancel();
                                _startHideTimer();
                              }
                            });
                          },
                        )
                      ),
                      Flexible(
                        flex: 5,
                        child: GestureDetector(
                          onDoubleTap: () {
                            _skip(_skipAmount);
                          },
                          onTap: () {
                            setState(() {
                              _controlsVisible = !_controlsVisible;
                              if (_controlsVisible) {
                                _hideTimer?.cancel();
                                _startHideTimer();
                              }
                            });
                          },
                          onVerticalDragUpdate: (details) {
                            print(details.delta);
                          },
                        )
                      )
                    ],
                  ),
                  IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        _latestValue.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 46.0,
                      ),
                      onTap: _playPause
                    )
                  ),
                ],
              )
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: LyreVideoProgressBar(controller)
        )
      ],
    );
  }
  String _formatDuration(Duration position) {
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
}