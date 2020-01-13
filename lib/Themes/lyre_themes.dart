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

class defaultLyreThemes {
  static LyreTheme darkTeal = LyreTheme(
    name: "Dark Teal",
    primaryColor: _getC(34, 34, 34),
    accentColor: _getC(128, 255, 212),
    highLightColor: _getC(255, 86, 34),
    primaryTextColor: _getC(255, 255, 255),
    secondaryTextColor: _getC(141, 141, 141),
    pinnedTextColor: _getC(55, 219, 96),
    canvasColor: _getC(18, 18, 18),
    contentBackgroundColor: _getC(28, 30, 32),

    borderRadius: 10,
    contentElevation: 3.5
  );
  static LyreTheme lightBlue = LyreTheme(
    name: "Light Blue",

    primaryColor: _getC(133, 177, 255),
    accentColor: _getC(225, 115, 255),
    highLightColor: _getC(252, 73, 118),
    primaryTextColor: _getC(87, 94, 105),
    secondaryTextColor: _getC(107, 112, 120),
    pinnedTextColor: _getC(55, 219, 96),
    canvasColor: _getC(228, 228, 228),
    contentBackgroundColor: _getC(255, 255, 255),

    borderRadius: 10,
    contentElevation: 3.5
  );
}
