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
          
        ],
    );
  }
}

class SingleImageViewer extends StatelessWidget {
  final previewUrl;

  SingleImageViewer(this.previewUrl);
  
  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: AdvancedNetworkImage(
        previewUrl,
        useDiskCache: true,
        cacheRule: const CacheRule(maxAge: Duration(days: 7)),
      ),
      loadingChild: const Center(child: const CircularProgressIndicator(),),
    );
  }
}