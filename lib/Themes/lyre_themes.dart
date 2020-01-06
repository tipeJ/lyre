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
    primaryColor: _getC(50,50,50),
    cardColor: _darkenColor(50, 50, 50),
    primaryColorDark: _darkenColor(45, 45, 45),
    canvasColor: _getC(25, 25, 25),
    primaryTextTheme: TextTheme(
      body1: TextStyle(fontSize: 9.0, color: Colors.red)
    ),
    accentColor: Colors.tealAccent
  ),
  LyreTheme.TerraCotta: ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.amber[200],
    primaryColorDark: Colors.amber[300],
    accentColor: _getC(230, 95, 92),
    canvasColor: _getC(25, 25, 25),
  ),
  LyreTheme.LightBlue: ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue[200],
    primaryColorDark: Colors.blue[400],
    accentColor: Colors.indigoAccent
  ),
  LyreTheme.DarkVanilla: ThemeData(
    brightness: Brightness.light,
    primaryColor: _getC(225, 176, 126),
    primaryColorDark: _darkenColor(225, 176, 126),
    canvasColor: _getC(203, 192, 173),
    accentColor: _getC(54, 29, 46)
  ),
  LyreTheme.DavyGrey: ThemeData(
    brightness: Brightness.dark,
    primaryColor: _getC(30, 168, 150),
    primaryColorDark: _darkenColor(30, 168, 150),
    canvasColor: _getC(76, 84, 84),
    accentColor: _getC(255, 113, 91)
  ),
  LyreTheme.NavyPurple: ThemeData(
    brightness: Brightness.light,
    primaryColor: _getC(225, 187, 201),
    primaryColorDark: _darkenColor(225, 187, 201),
    accentColor: _getC(177, 74, 237)
  ),
  LyreTheme.WeldonBlue: ThemeData(
    brightness: Brightness.dark,
    primaryColor: _getC(119, 152, 171),
    primaryColorDark: _darkenColor(119, 152, 171),
    canvasColor: _getC(13, 27, 30),
    accentColor: _getC(242, 206, 230)
  ),
  LyreTheme.LemonMeringue: ThemeData(
    brightness: Brightness.light,
    primaryColor: _getC(192, 132, 151),
    primaryColorDark: _darkenColor(192, 132, 151),
    canvasColor: _getC(243, 238, 195),
    accentColor: _getC(176, 208, 211)
  ),
  LyreTheme.LemonMeringue2: ThemeData(
    brightness: Brightness.light,
    primaryColor: _getC(247, 175, 157),
    primaryColorDark: _darkenColor(247, 175, 157),
    canvasColor: _getC(243, 238, 195),
    accentColor: _getC(176, 208, 211)
  ),
};
Color _darkenColor(int r, int g, int b){
  //How much the color is darkened. 1.0 is the same, 0.0 is completely black.
  double darkener = 0.9;
  return _getC((r * darkener).round(), (g * darkener).round(), (b * darkener).round());
}
Color _getC(int r, int g, int b){
  return Color.fromRGBO(r, g, b, 1.0);
}