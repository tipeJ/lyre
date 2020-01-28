import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Themes/themes.dart';

part "theme.g.dart";

@HiveType(typeId: 1, adapterName: "LyreThemeAdapter")
class LyreTheme {

  LyreTheme({
    this.dark,
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
    this.contentElevation,
    this.cardMargin
  }) : 
    this.primaryColor = primaryColor.toHex(),
    this.accentColor = accentColor.toHex(),
    this.highLightColor = highLightColor.toHex(),
    this.primaryTextColor = primaryTextColor.toHex(),
    this.secondaryTextColor = secondaryTextColor.toHex(),
    this.pinnedTextColor = pinnedTextColor.toHex(),
    this.canvasColor = canvasColor.toHex(),
    this.contentBackgroundColor = contentBackgroundColor.toHex();

  @HiveField(11)
  final bool dark;

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

  @HiveField(12)
  final double cardMargin;

  ThemeData get toThemeData => ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    primaryColor: HexColor.fromHex(primaryColor),
    cardColor: HexColor.fromHex(contentBackgroundColor),
    accentColor: HexColor.fromHex(accentColor),
    highlightColor: HexColor.fromHex(highLightColor),
    splashColor: Colors.grey,
    textTheme: TextTheme(
      body1: TextStyle(color: HexColor.fromHex(primaryTextColor)),
      body2: TextStyle(
        color: HexColor.fromHex(secondaryTextColor),
        fontSize: 11.0,
        fontWeight: FontWeight.normal
      ),
      display1: TextStyle(color: HexColor.fromHex(primaryTextColor)),
      title: TextStyle(color: HexColor.fromHex(primaryTextColor))
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: _inputHelpText,
      labelStyle: _inputHelpText,
      helperStyle: _inputHelpText,
      prefixStyle: _inputHelpText,
      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: HexColor.fromHex(accentColor))),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: HexColor.fromHex(secondaryTextColor))),
    ),
    buttonColor: HexColor.fromHex(accentColor),
    canvasColor: HexColor.fromHex(canvasColor),
    backgroundColor: HexColor.fromHex(contentBackgroundColor),
    iconTheme: IconThemeData(color: HexColor.fromHex(secondaryTextColor)),
    cardTheme: CardTheme(
      margin: EdgeInsets.all(cardMargin),
      elevation: contentElevation, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble())),
      clipBehavior: Clip.hardEdge
    ),
    buttonTheme: ButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius.toDouble()), side: BorderSide(color: HexColor.fromHex(secondaryTextColor))),
      buttonColor: HexColor.fromHex(accentColor),
      textTheme: ButtonTextTheme.primary
    ),
    bottomSheetTheme: BottomSheetThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(borderRadius.toDouble()), topRight: Radius.circular(borderRadius.toDouble()))),
      backgroundColor: HexColor.fromHex(primaryColor)
    )
  );
  TextStyle get _inputHelpText => TextStyle(
    color: HexColor.fromHex(secondaryTextColor),
    fontSize: 14.0,
    fontWeight: FontWeight.normal
  );
}