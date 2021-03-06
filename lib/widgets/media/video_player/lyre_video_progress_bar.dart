import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

class LyreVideoProgressBar extends StatefulWidget {
  LyreVideoProgressBar(
    this.controller, {
    this.onDragEnd,
    this.onDragStart,
    this.onDragUpdate,
  });

  final VideoPlayerController controller;
  final Function() onDragStart;
  final Function() onDragEnd;
  final Function() onDragUpdate;

  @override
  _VideoProgressBarState createState() {
    return _VideoProgressBarState();
  }
}

const _barHeight = 10.0;
const _touchPadding = 50.0;

class _VideoProgressBarState extends State<LyreVideoProgressBar> {
  

  _VideoProgressBarState() {
    listener = () {
      setState(() {});
    };
  }

  VoidCallback listener;
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return GestureDetector(
      child: Container(
          padding: const EdgeInsets.only(top: _touchPadding),
          height: _barHeight + _touchPadding,
          width: MediaQuery.of(context).size.width,
          color: Colors.transparent,
          child: CustomPaint(
            painter: _ProgressBarPainter(
              controller.value,
              Theme.of(context),
            ),
          ),
        ),
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }

        if (widget.onDragStart != null) {
          widget.onDragStart();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);

        if (widget.onDragUpdate != null) {
          widget.onDragUpdate();
        }
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying) {
          controller.play();
        }

        if (widget.onDragEnd != null) {
          widget.onDragEnd();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.initialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  _ProgressBarPainter(this.value, this.themeData);

  VideoPlayerValue value;
  ThemeData themeData;

  @override
  bool shouldRepaint(CustomPainter painter) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final height = _barHeight;

    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromPoints(
        Offset(0.0, size.height / 2),
        Offset(size.width, size.height / 2 + height),
      )),
      Paint()..color = Colors.transparent
    );
    if (!value.initialized) {
      return;
    }
    final double playedPartPercent =
        value.position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart =
        playedPartPercent > 1 ? size.width : playedPartPercent * size.width;
    for (DurationRange range in value.buffered) {
      final double start = range.startFraction(value.duration) * size.width;
      final double end = range.endFraction(value.duration) * size.width;
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromPoints(
          Offset(start, size.height / 2),
          Offset(end, size.height / 2 + height),
        )),
        Paint()..color = Colors.black38
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(Rect.fromPoints(
        Offset(0.0, size.height / 2),
        Offset(playedPart, size.height / 2 + height),
      )),
      Paint()..color = Colors.white70
    );
  }
}
