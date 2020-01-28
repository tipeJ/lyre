import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Themes/themes.dart';

class ThemeView extends StatelessWidget {
  const ThemeView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [Container()],
        title: Text("Themes"),
      ),
      body: Container(
        padding: const EdgeInsets.all(10.0),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Text("Default Themes", style: Theme.of(context).textTheme.title)
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                defaultLyreThemes.defaultThemes.map((theme) => _ThemeDisplayWidget(lyreTheme: theme, isDefault: true)).toList()
              ),
            )
          ],
        )
      ),
    );
  }
}
class _ThemeDisplayWidget extends StatelessWidget {
  final ThemeData _theme;
  final LyreTheme lyreTheme;
  final bool isDefault;
  _ThemeDisplayWidget({@required this.lyreTheme, @required this.isDefault, Key key}) : _theme = lyreTheme.toThemeData, super(key: key);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme,
      child: Card(
        margin: EdgeInsets.all(5.0),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Text(lyreTheme.name, style: _theme.textTheme.title),
                  Row(
                    children: <Widget>[
                      Text("Some Text", style: _theme.textTheme.body2)
                    ],
                  )
                ]
              ),
              const Spacer(),
              InkWell(
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(Icons.menu),
                ),
                onTap: () {
                  
                },
              ),
              isDefault
                ? null
                : InkWell(
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(Icons.edit),
                    ),
                    onTap: () {
                      
                    },
                  ),
            ].where((w) => notNull(w)).toList(),
          )
        ),
      ),
    );
  }
}