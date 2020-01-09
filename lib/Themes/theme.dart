import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Themes/themes.dart';

part "theme.g.dart";

@HiveType(typeId: 1, adapterName: "LyreThemeAdapter")
class LyreTheme {

  LyreTheme({
    this.name,
    Color primaryColor,
    Color accentColor,
    Color highLightColor,
    Color primaryTextColor,
    Color secondaryTextColor,
    Color pinnedTextColor,
    Color canvasColor,
    Color contentBackgroundColor,
    this.borderRadius,
  }) : 
    this.primaryColor = primaryColor.toHex(),
    this.accentColor = accentColor.toHex(),
    this.highLightColor = highLightColor.toHex(),
    this.primaryTextColor = primaryTextColor.toHex(),
    this.secondaryTextColor = secondaryTextColor.toHex(),
    this.pinnedTextColor = pinnedTextColor.toHex(),
    this.canvasColor = canvasColor.toHex(),
    this.contentBackgroundColor = contentBackgroundColor.toHex();

  @HiveField(0)
  final String name;

  @HiveField(1)
  final String primaryColor;
  @HiveField(2)
  final String accentColor;
  @HiveField(3)
  final String highLightColor;
  @HiveField(4)
  final String primaryTextColor;
  @HiveField(5)
  final String secondaryTextColor;
  @HiveField(6)
  final String pinnedTextColor;
  @HiveField(7)
  final String canvasColor;
  @HiveField(8)
  final String contentBackgroundColor;

  @HiveField(9)
  final int borderRadius;

  ThemeData get toThemeData => ThemeData(
    primaryColor: HexColor.fromHex(primaryColor),
    cardColor: HexColor.fromHex(primaryColor),
    accentColor: HexColor.fromHex(accentColor),
    highlightColor: HexColor.fromHex(highLightColor),
    textTheme: TextTheme(
      body1: TextStyle(color: HexColor.fromHex(primaryTextColor)),
      body2: TextStyle(color: HexColor.fromHex(secondaryTextColor)),
      display1: TextStyle(color: HexColor.fromHex(pinnedTextColor)),
      display2: TextStyle(color: HexColor.fromHex(pinnedTextColor)),
      display3: TextStyle(color: HexColor.fromHex(pinnedTextColor)),
      display4: TextStyle(color: HexColor.fromHex(pinnedTextColor)),
    ),
    buttonColor: HexColor.fromHex(accentColor),
    canvasColor: HexColor.fromHex(canvasColor),
    backgroundColor: HexColor.fromHex(contentBackgroundColor),
    buttonTheme: ButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble()))),
    bottomSheetTheme: BottomSheetThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble())))
  );
}