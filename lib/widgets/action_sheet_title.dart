import 'package:flutter/material.dart';
import 'package:lyre/Themes/themes.dart';

class ActionSheetTitle extends StatelessWidget {
  final String title;
  final VoidCallback actionCallBack;
  final bool showAction;

  const ActionSheetTitle({@required this.title, this.actionCallBack, this.showAction = true, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(
              title, 
              maxLines: 1,
              softWrap: true,
              style: LyreTextStyles.bottomSheetTitle,
            )
          ),
          showAction
            ? InkWell(
                child: const Padding(
                  child: Icon(Icons.close),
                  padding: EdgeInsets.all(10.0),
                ),
                onTap: actionCallBack ?? (){
                  Navigator.of(context).pop();
                },
              )
            // Empty container in place of close button
            : Container()
        ],
      )
    );
  }
}

/// Options button for all types of bottom action sheets.
class ActionSheetInkwell extends StatelessWidget {
  /// Widget to be shown in the inkwell
  final Widget title;
  /// Action for the inkwell
  final VoidCallback onTap;

  const ActionSheetInkwell({
    @required this.title, 
    @required this.onTap, 
    Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        alignment: Alignment.centerLeft,
        height: 50.0,
        child: title,
      ),
      onTap: onTap
    );
  }
}