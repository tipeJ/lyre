import 'dart:math';
import 'package:lyre/Themes/themes.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lyre/Themes/content_sizes.dart';
import 'package:lyre/utils/share_utils.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class InputOptions extends StatelessWidget {
  final TextEditingController controller;

  String get _text => controller.text;

  const InputOptions({@required this.controller, key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Material(
        color: Theme.of(context).primaryColor,
        child: Row(children: _buttons(context),)
      ),
      scrollDirection: Axis.horizontal,
    );
  }

  /// InputOptions buttons
  List<Widget> _buttons (BuildContext context) => [
    IconButton(
      icon: Icon(MdiIcons.formatHeader1),
      onPressed: _handleHeader1Click,
    ),
    IconButton(
      icon: Icon(MdiIcons.formatHeader2),
      onPressed: _handleHeader2Click,
    ),
    IconButton(
      icon: Icon(Icons.format_bold),
      onPressed: _handleBoldClick,
    ),
    IconButton(
      icon: Icon(Icons.format_italic),
      onPressed: _handleItalicsClick,
    ),
    IconButton(
      icon: Icon(Icons.format_strikethrough),
      onPressed: _handleStrikethroughClick,
    ),
    // ! Not yet supported by flutter_markdown
    // IconButton(
    //   icon: Icon(MdiIcons.eyeOff),
    //   onPressed: _handleSpoilerClick,
    // ),
    IconButton(
      icon: Icon(Icons.format_quote),
      onPressed: _handleQuoteClick,
    ),
    // ! Not yet supported by flutter_markdown
    // IconButton(
    //   icon: Icon(MdiIcons.exponent),
    //   onPressed: _handleExponentClick,
    // ),
    IconButton(
      icon: Icon(Icons.link),
      onPressed: () => _handleLinkClick(context),
    ),
    IconButton(
      icon: Icon(Icons.format_list_bulleted),
      onPressed: _handleBulletListclick,
    ),
    IconButton(
      icon: Icon(Icons.format_list_numbered),
      onPressed: _handleNumberedListclick,
    ),
    IconButton(
      icon: Icon(MdiIcons.eyeOutline),
      onPressed: () => _handlePreviewClick(context),
    ),
  ];

  void _handleHeader1Click() {
    if (controller.selection.isCollapsed) {
      var text = _text;
      final initialOffset = controller.selection.base.offset-1;
      final lineBreak = _firstOccurrence(char: '\n', startIndex: initialOffset, direction: -1);

      text = StringUtils.addCharAtPosition(text, '# ', lineBreak == 0 ? lineBreak : lineBreak + 1);
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+3));
    }
  }

  void _handleHeader2Click() {
    if (controller.selection.isCollapsed) {
      var text = _text;
      final initialOffset = controller.selection.base.offset-1;
      final lineBreak = _firstOccurrence(char: '\n', startIndex: initialOffset, direction: -1);

      text = StringUtils.addCharAtPosition(text, '## ', lineBreak == 0 ? lineBreak : lineBreak + 1);
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+4));
    }
  }

  void _handleBoldClick() {
    if (controller.selection.isCollapsed) {  
      var text = controller.text;
      final initialOffset = controller.selection.base.offset;

      text += '****';
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+2));
    }
  }

  void _handleItalicsClick() {
    if (controller.selection.isCollapsed) {
      var text = controller.text;
      final initialOffset = controller.selection.base.offset;

      text += '**';
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+1));
    }
  }

  void _handleStrikethroughClick() {
    if (controller.selection.isCollapsed) {
      var text = controller.text;
      final initialOffset = controller.selection.base.offset;

      text += '~~~~';
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+2));
    }
  }
  // ! Not yet supported by flutter_markdown
  // void _handleSpoilerClick() {
  //   if (controller.selection.isCollapsed) {
  //     var text = controller.text;
  //     final initialOffset = controller.selection.base.offset;

  //     text += '>!!<';
  //     controller.text = text;
  //     controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+2));
  //   }
  // }

  // void _handleExponentClick() {
  //   if (controller.selection.isCollapsed) {
  //     var text = controller.text;
  //     final initialOffset = controller.selection.base.offset;

  //     text += '^';
  //     controller.text = text;
  //     controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+1));
  //   }
  // }

  void _handleQuoteClick() {
    if (controller.selection.isCollapsed) {
      var text = _text;
      final initialOffset = controller.selection.base.offset-1;
      final lineBreak = _firstOccurrence(char: '\n', startIndex: initialOffset, direction: -1);

      text = StringUtils.addCharAtPosition(text, '> ', lineBreak == 0 ? lineBreak : lineBreak + 1);
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset+3));
    }
  }

  void _handleLinkClick(BuildContext context) {
    if (controller.selection.isCollapsed) {
      final Widget linkSheet = Container(
        padding: EdgeInsets.all(10.0),
        child: _LinkInputSheet(
          onSubmitted: ({String text, String link}) {
            var controllertext = _text;
            final initialOffset = controller.selection.base.offset;
            
            controllertext += " [$text]($link)";
            controller.text = controllertext;
            controller.selection = TextSelection.fromPosition(TextPosition(offset: (initialOffset + text.length + link.length + 6)));
          },
        )
      );
      // showDialog(context: context, child: dialog);
      showBottomSheet( 
        context: context,
        builder: (context) => linkSheet,
        backgroundColor: Theme.of(context).primaryColor
       );
    }
  }

  void _handleBulletListclick() {
    if (controller.selection.isCollapsed) {
      var text = _text;
      final initialOffset = max(0, controller.selection.base.offset-1);

      text += initialOffset == 0 ? '* ' : '\n* ';
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset == 0 ? initialOffset + 1 : initialOffset+4));
    }
  }

  void _handleNumberedListclick() {
    if (controller.selection.isCollapsed) {
      var text = _text;
      final initialOffset = controller.selection.base.offset;
      var secondToLastLineBreak = _firstOccurrence(char: '\n', startIndex: initialOffset - 1, direction: -1);
      if (secondToLastLineBreak > 0) secondToLastLineBreak++;

      print(secondToLastLineBreak.toString() + ' : ' + text.length.toString());

      int lastNumber;
      bool increment = text.isEmpty || secondToLastLineBreak == text.length ? false : text.substring(secondToLastLineBreak+1, secondToLastLineBreak+2) == ".";
      if (increment) {
        lastNumber = int.parse(text.substring(secondToLastLineBreak, secondToLastLineBreak+1));
      }
      // This is the number that will be added to the text before the point character (.)
      int nextNumber = lastNumber != null ? lastNumber + 1 : 1;
      print(nextNumber);

      text += initialOffset == 0 ? '$nextNumber. ' : '\n$nextNumber. ';
      controller.text = text;
      controller.selection = TextSelection.fromPosition(TextPosition(offset: initialOffset == 0 ? initialOffset + 3 : initialOffset+4));
    }
  }

  void _handlePreviewClick(BuildContext context) {
    if (_text.isNotEmpty) {
      final sheet = DraggableScrollableSheet(
        initialChildSize: 0.2,
        minChildSize: 0.2,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, controller) => Material(
          color: Theme.of(context).primaryColor,
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: ListView(
              controller: controller,
              children: <Widget>[
                Container(
                  constraints: BoxConstraints.tightFor(height: 30.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Markdown Preview')
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: (){
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  )
                ),
                Divider(),
                SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  controller: controller,
                  child: MarkdownBody(
                    data: _text,
                    styleSheet: LyreTextStyles.getMarkdownStyleSheet(context)
                  ),
                )
              ],
            )
          )
        )
      );
      showBottomSheet(
        context: context,
        builder: (context) => sheet
      );
    }
  }

  /// Find the first occurrence of given [String] char. Starts from the startIndex parameters and moves in direction determined by the direction paramter
  /// (negative for towards the start, positive for towards the end) SkipAmount must be positive or zero.
  int _firstOccurrence({String char, int startIndex, int direction, int skipAmount = 0}) {
    for (var i = startIndex; (direction < 0) ? i > 0 : i < _text.length; direction < 0 ? i-- : i++) {
      if (_text[i] == char) {
        if (skipAmount == 0) {
          return i;
        }
        skipAmount--;
      }
    }
    return direction < 0 ? 0 : _text.length-1;
  }
  String _replaceCharAt(String oldString, int index, String newChar) {
    return oldString.substring(0, index) + newChar + oldString.substring(index + 1);
  }
}

class _LinkInputSheet extends StatefulWidget {
  const _LinkInputSheet({@required this.onSubmitted, Key key}) : super(key: key);

  final Function({String text, String link}) onSubmitted;

  @override
  __LinkInputSheetState createState() => __LinkInputSheetState();
}

class __LinkInputSheetState extends State<_LinkInputSheet> {
  TextEditingController _textInputController;
  TextEditingController _linkInputController;
  
  @override
  void initState() {
    _textInputController = TextEditingController();
    _textInputController.addListener((){
      setState((){});
    });
    _linkInputController = TextEditingController();
    _linkInputController.addListener((){
      setState((){});
    });
    super.initState();
  }

  @override
  void dispose() { 
    _textInputController.dispose();
    _linkInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column (
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Text('Insert a link'),
            const Spacer(),
            OutlineButton(
              child: const Text("Cancel"), 
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
            OutlineButton(
              child: const Text("OK"), 
              onPressed: _textInputController.text.isNotEmpty && _linkInputController.text.isNotEmpty ? _submit : null,
            )
          ],
        ),
        Row(children: <Widget>[
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: "Text"),
              controller: _textInputController,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_paste, size: LyreContentSizes.editingIconSize,),
            onPressed: () async {
              final clipBoardText = await getClipBoard();
              _textInputController.text += clipBoardText;
            },
          )
        ],),
        Row(children: <Widget>[
          Expanded(
            child: TextField(
              decoration: const InputDecoration(labelText: "Link Url"),
              controller: _linkInputController,
              onEditingComplete: _submit,
            )
          ),
          IconButton(
            icon: const Icon(Icons.content_paste, size: LyreContentSizes.editingIconSize,),
            onPressed: () async {
              final clipBoardText = await getClipBoard();
              _linkInputController.text += clipBoardText;
            },
          )
        ],),
      ],
    );
  }
  _submit() {
    widget.onSubmitted(text: _textInputController.text, link: _linkInputController.text);
    Navigator.of(context).pop();
  }
}