import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class LyreTextStyles {
  static const errorMessage = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.bold
  );

  static const title = TextStyle(fontSize: 35.0);
  static const titleSmaller = TextStyle(fontSize: 28.0);

  static const dialogTitle = TextStyle(fontSize: 24.0);

  static bottomSheetTitle(BuildContext context) => TextStyle(fontSize: 16.0, color: Theme.of(context).primaryTextTheme.display1.color, fontWeight: FontWeight.bold);

  static const typeParams = TextStyle(fontSize: 26.0);
  static const timeParams = TextStyle(fontSize: 13.0);
  static const iconText = TextStyle(fontSize: 20.0, fontWeight: FontWeight.w500);

  static const submissionTitle = TextStyle(fontSize: 18.0, fontWeight: FontWeight.w400);
  static const submissionPreviewSelftext = TextStyle(fontSize: 13.0, fontWeight: FontWeight.normal);

  static MarkdownStyleSheet getMarkdownStyleSheet(BuildContext context) => MarkdownStyleSheet(
    tableCellsDecoration: BoxDecoration(color: Theme.of(context).cardColor),
    p: Theme.of(context).primaryTextTheme.body1,
    a: TextStyle(color: Theme.of(context).accentColor),
    h1: Theme.of(context).primaryTextTheme.body1,
    h2: Theme.of(context).primaryTextTheme.body1,
    h3: Theme.of(context).primaryTextTheme.body1,
    h4: Theme.of(context).primaryTextTheme.body1,
    h5: Theme.of(context).primaryTextTheme.body1,
    h6: Theme.of(context).primaryTextTheme.body1,
    tableHead: Theme.of(context).primaryTextTheme.display1,
    tableBody: Theme.of(context).primaryTextTheme.body1,
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3.5))
    ),
  );
}