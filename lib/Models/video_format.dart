import 'package:equatable/equatable.dart';

/// Class for storing info of network videos. Normal direct links do not need these, as the don't retrieve thumbnails
class LyreVideoFormat extends Equatable{
  
  /// Video format id (i.e mp4)
  final String formatId;

  /// The Main video url
  final String url;

  /// Video width (in pixels)
  final int width;

  /// Video height (in pixels)
  final int height;

  /// Video duration
  final double duration;

  /// Video file size
  final int filesize;

  /// Video bitrate
  final int bitrate;

  /// Video framerate
  final double framerate;

  const LyreVideoFormat({
    this.formatId,
    this.url,
    this.width,
    this.height,
    this.duration,
    this.filesize,
    this.bitrate,
    this.framerate
  });

  List get props => [formatId, url, width, height, duration, filesize, bitrate, framerate];
}