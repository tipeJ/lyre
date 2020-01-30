import 'package:flutter/material.dart';
import 'package:lyre/utils/utils.dart';

// Easter egg stuff. Not really important. Made under the influence of extreme boredom

SnackBar easter_iosSnackBar(BuildContext context) => SnackBar(
  content: Text("Imagine actually using iOS in ${DateTime.now().year}"),
  action: SnackBarAction(
    label: "Upgrade",
    onPressed: () => launchURL(context, "https://www.ebay.com/sch/i.html?_from=R40&_trksid=m570.l1313&_nkw=Samsung+Continuum&_sacat=0"),
  ),
);
const SnackBar easter_androidSnackBar = SnackBar(
  content: Text("You Don't. You've already got the best one out there")
);
const SnackBar easter_getkarmaSnackbar = SnackBar(
  content: Text("Take a creative writing course, pick a submission from top-all of r/pics and repost it with a new title")
);
const SnackBar easter_goldSnackbar = SnackBar(
  content: Text("Something useless. Don't buy it")
);
const SnackBar easter_redditorSnackBar = SnackBar(
  content: Text("Yes. Unfortunately, as you'll soon discover")
);
const SnackBar easter_nativeadsSnackBar = SnackBar(
  content: Text("Just install an ad-free client 😂😂😂😂😂")
);