import 'package:flutter/material.dart';
import 'package:lyre/Themes/themes.dart';



Color _darkenColor(int r, int g, int b){
  //How much the color is darkened. 1.0 is the same, 0.0 is completely black.
  double darkener = 0.9;
  return _getC((r * darkener).round(), (g * darkener).round(), (b * darkener).round());
}
Color _getC(int r, int g, int b){
  return Color.fromRGBO(r, g, b, 1.0);
}

LyreTheme darkTeal = LyreTheme(
  name: "Dark Teal",
  primaryColor: _getC(55, 55, 55),
  accentColor: _getC(128, 255, 212),
  highLightColor: Color.fromARGB(125, 106, 223, 230),
  primaryTextColor: _getC(245, 245, 245),
  secondaryTextColor: _getC(220, 220, 220),
  pinnedTextColor: _getC(55, 219, 96),
  canvasColor: _getC(18, 18, 18),
  contentBackgroundColor: _getC(219, 69, 55),

  borderRadius: 10
);
LyreTheme lightBlue = LyreTheme(
  primaryColor: _getC(240, 240, 240)
);