import 'package:flutter/material.dart';

enum LyreTheme{
  DarkTeal,
  TerraCotta,
  LightBlue,
  DarkVanilla,
  DavyGrey,
  NavyPurple,
  WeldonBlue,
  LemonMeringue,
  LemonMeringue2
}

final lyreThemeData = {
  LyreTheme.DarkTeal: ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.teal[200],
    primaryColorDark: Colors.teal[300],
    accentColor: Colors.tealAccent
  ),
  LyreTheme.TerraCotta: ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.amber[200],
    primaryColorDark: Colors.amber[300],
    accentColor: getC(230, 95, 92),
    canvasColor: getC(15, 3, 38)
  ),
  LyreTheme.LightBlue: ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue[200],
    primaryColorDark: Colors.blue[400],
    accentColor: Colors.indigoAccent
  ),
  LyreTheme.DarkVanilla: ThemeData(
    brightness: Brightness.light,
    primaryColor: getC(225, 176, 126),
    primaryColorDark: darkenColor(225, 176, 126),
    canvasColor: getC(203, 192, 173),
    accentColor: getC(54, 29, 46)
  ),
  LyreTheme.DavyGrey: ThemeData(
    brightness: Brightness.dark,
    primaryColor: getC(30, 168, 150),
    primaryColorDark: darkenColor(30, 168, 150),
    canvasColor: getC(76, 84, 84),
    accentColor: getC(255, 113, 91)
  ),
  LyreTheme.NavyPurple: ThemeData(
    brightness: Brightness.light,
    primaryColor: getC(177, 74, 237),
    primaryColorDark: darkenColor(177, 74, 237),
    canvasColor: getC(225, 187, 201),
    accentColor: getC(27, 31, 59)
  ),
  LyreTheme.WeldonBlue: ThemeData(
    brightness: Brightness.dark,
    primaryColor: getC(119, 152, 171),
    primaryColorDark: darkenColor(119, 152, 171),
    canvasColor: getC(13, 27, 30),
    accentColor: getC(242, 206, 230)
  ),
  LyreTheme.LemonMeringue: ThemeData(
    brightness: Brightness.light,
    primaryColor: getC(192, 132, 151),
    primaryColorDark: darkenColor(192, 132, 151),
    canvasColor: getC(243, 238, 195),
    accentColor: getC(176, 208, 211)
  ),
  LyreTheme.LemonMeringue2: ThemeData(
    brightness: Brightness.light,
    primaryColor: getC(247, 175, 157),
    primaryColorDark: darkenColor(247, 175, 157),
    canvasColor: getC(243, 238, 195),
    accentColor: getC(176, 208, 211)
  ),
};
Color darkenColor(int r, int g, int b){
  //How much the color is darkened. 1.0 is the same, 0.0 is completely black.
  double darkener = 0.9;
  return getC((r * darkener).round(), (g * darkener).round(), (b * darkener).round());
}
Color getC(int r, int g, int b){
  return Color.fromRGBO(r, g, b, 1.0);
}