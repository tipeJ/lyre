import 'utils.dart';
import 'package:lyre/screens/interfaces/previewc.dart';
import 'package:flutter/material.dart';

/// Handles link clicks
/// Supply context if a direct launching web link
void handleLinkClick(String url, [LinkType suppliedLinkType, BuildContext context]) {
  print(url);
  final LinkType linkType = suppliedLinkType ?? getLinkType(url);
  if(linkType == LinkType.YouTube){
    //TODO: Implement YT plugin?
    launchURL(context, url);
  } else if (linkType == LinkType.Default){
    launchURL(context, url);
  } else {
    PreviewCall().callback.preview(url);
  }
}