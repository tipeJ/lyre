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
    this.contentElevation
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
  @HiveField(10)
  final double contentElevation;

  ThemeData get toThemeData => ThemeData(
    // brightness: Brightness.light,
    primaryColor: HexColor.fromHex(primaryColor),
    cardColor: HexColor.fromHex(contentBackgroundColor),
    accentColor: HexColor.fromHex(accentColor),
    highlightColor: HexColor.fromHex(highLightColor),
    textTheme: Typography.whiteMountainView..apply(
      bodyColor: HexColor.fromHex(primaryTextColor),
      displayColor: HexColor.fromHex(secondaryTextColor),
    ),
    buttonColor: HexColor.fromHex(accentColor),
    canvasColor: HexColor.fromHex(canvasColor),
    backgroundColor: HexColor.fromHex(contentBackgroundColor),
    iconTheme: IconThemeData(color: HexColor.fromHex(primaryTextColor)),
    cardTheme: CardTheme(elevation: contentElevation, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble()))),
    buttonTheme: ButtonThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble()))),
    bottomSheetTheme: BottomSheetThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble())))
  );
}