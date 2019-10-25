import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lyre/utils/urlUtils.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewer extends StatelessWidget {
  final LinkType linkType;
  final String previewUrl;

  ImageViewer({this.previewUrl, this.linkType});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: albumLinkTypes.contains(linkType) 
        ? <Widget> [
          
        ]
        : <Widget> [
          PhotoView(
            imageProvider: AdvancedNetworkImage(
              previewUrl,
              useDiskCache: true,
              cacheRule: CacheRule(maxAge: Duration(days: 7))
            ),
          )
        ],
    );
  }
}

class SingleImageViewer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      
    );
  }
}