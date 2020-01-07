import 'package:flutter/material.dart';
import 'package:lyre/Themes/themes.dart';

class BottomSheetTitle extends StatelessWidget {
  final String title;
  final VoidCallback actionCallBack;

  const BottomSheetTitle({@required this.title, this.actionCallBack, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(title, style: LyreTextStyles.bottomSheetTitle,)
          ),
          InkWell(
            child: const Padding(
              child: Icon(Icons.close),
              padding: EdgeInsets.all(10.0),
            ),
            onTap: actionCallBack ?? (){
              Navigator.of(context).pop();
            },
          )
        ],
      )
    );
  }
}