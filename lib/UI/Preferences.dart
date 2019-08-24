import 'package:flutter/material.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import '../Themes/themes.dart';
import '../Themes/bloc/theme_bloc.dart';
import '../Themes/bloc/theme_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesView extends StatelessWidget {
  SharedPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Container(
          padding: EdgeInsets.all(10.0),
          child: FutureBuilder(
            future: SharedPreferences.getInstance(),
            builder: (context, AsyncSnapshot<SharedPreferences> snapshot){
              if(snapshot.hasData){
                preferences = snapshot.data;
                return ListView(
                  children: <Widget>[
                    CustomExpansionTile(
                      title: 'Themes',
                      children: getThemeList(context),
                    ),
                    CustomExpansionTile(
                      title: 'Filters',
                      children: getFiltersList(context),
                    )
                  ],
                );
              } else {
                return Container(
                  width: 25.0,
                  height: 25.0,
                  child: Center(child: CircularProgressIndicator(),),
                );
              }
            },
          )
      )
    ));
  }
  List<Widget> getFiltersList(BuildContext context){
    return [
      getSettingsTitleRow(
        'Show NSFW Previews', 
        Switch(
          value: preferences.getBool('showNSFWPreviews') != null ? preferences.getBool('showNSFWPreviews') : false,
          onChanged: (value){
            preferences.setBool('showNSFWPreviews', value);
          },)
      )
    ];
  }
  List<Widget> getThemeList(BuildContext context){
    List<Widget> list = [];
    LyreTheme.values.forEach((lyreAppTheme){
      list.add(Container(
        decoration: BoxDecoration(
          color: lyreThemeData[lyreAppTheme].primaryColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8.0),
          border: preferences.get('currentTheme') == lyreAppTheme.toString()
            ? Border.all(
              color: Theme.of(context).accentColor,
              width: 3.5
            )
            : null
        ),
        margin: EdgeInsets.all(10.0),
        child: ListTile(
          title: Text(
            lyreAppTheme.toString(),
            style: lyreThemeData[lyreAppTheme].textTheme.body1
          ),
          onTap: (){
            //Make the bloc output a new ThemeState
            SharedPreferences.getInstance().then((instance){
              instance.setString('currentTheme', lyreAppTheme.toString());
              BlocProvider.of<ThemeBloc>(context)
              .dispatch(ThemeChanged(theme: lyreAppTheme));
            });
          },
        ),
      ));
    });
    return list;
  }
  Row getSettingsTitleRow(String title, Widget leading){
    return Row(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(title),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.0),
          child: leading,
        )
      ],
    );
  }
}