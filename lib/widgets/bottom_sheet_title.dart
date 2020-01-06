import 'package:flutter/material.dart';
import 'package:lyre/Themes/themes.dart';

class BottomSheetTitle extends StatelessWidget {
  final String title;
  final VoidCallback actionCallBack;

  const BottomSheetTitle({@required this.title, this.actionCallBack, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.tightFor(height: 30.0),
      padding: const EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
      height: 50.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Text(title, style: LyreTextStyles.bottomSheetTitle,)
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: actionCallBack ?? (){
              Navigator.of(context).pop();
            },
          )
        ],
      )
    );
  }
}