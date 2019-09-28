import 'package:flutter/material.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import '../Themes/themes.dart';
import '../Themes/bloc/theme_bloc.dart';
import '../Themes/bloc/theme_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Resources/PreferenceValues.dart';

class PreferencesView extends StatefulWidget {
  PreferencesView({Key key}) : super(key: key);

  _PreferencesViewState createState() => _PreferencesViewState();
}
class _PreferencesViewState extends State<PreferencesView> {
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
                      title: 'Browsing',
                      children: getBrowsingSettings(context),
                    ),
                    CustomExpansionTile(
                      title: 'Filters',
                      children: getFiltersSettings(context),
                    ),
                    CustomExpansionTile(
                      title: 'Themes',
                      children: getThemeSettings(context),
                    ),
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
  List<Widget> getBrowsingSettings(BuildContext context){
    return [
      SettingsTitleRow(
        title: "Default sorting type",
        leading: new DropdownButton<String>(
          value: preferences.getString(DEFAULT_SORT_TYPE) != null ? preferences.getString(DEFAULT_SORT_TYPE) : sortTypes[0],
          items: sortTypes.map((String value) {
            return new DropdownMenuItem<String>(
              value: value,
              child: new Text(value),
            );
          }).toList(),
          onChanged: (value) {
            preferences.setString(DEFAULT_SORT_TYPE, value);
          },
        )
      ),
      StatefulBuilder(
        builder: (BuildContext context, setState) {
          return SettingsTitleRow(
            title: "Default sorting time",
            leading: new DropdownButton<String>(
              value: preferences.getString(DEFAULT_SORT_TIME) != null ? preferences.getString(DEFAULT_SORT_TIME) : sortTimes[1],
              items: sortTimes.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (value) {
                preferences.setString(DEFAULT_SORT_TIME, value);
                setState(() {
                });
              },
            )
          );
        },
      ),
      
      SettingsTitleRow(
        title: "Reset sorting when refreshing submission list",
        leading: Switch(
          value: preferences.getBool(RESET_SORTING) != null ? preferences.getBool(RESET_SORTING) : true,
          onChanged: (value){
            preferences.setBool(RESET_SORTING, value);
          },)
      ),
    ];
  }
  List<Widget> getFiltersSettings(BuildContext context){
    return [
      SettingsTitleRow(
        title: 'Show NSFW Previews', 
        leading: Switch(
          value: preferences.getBool(SHOW_NSFW_PREVIEWS) != null ? preferences.getBool(SHOW_NSFW_PREVIEWS) : false,
          onChanged: (value){
            preferences.setBool(SHOW_NSFW_PREVIEWS, value);
          },)
      )
    ];
  }
  List<Widget> getThemeSettings(BuildContext context){
    List<Widget> list = [];
    LyreTheme.values.forEach((lyreAppTheme){
      list.add(Container(
        decoration: BoxDecoration(
          color: lyreThemeData[lyreAppTheme].accentColor,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(8.0),
          border: preferences.get(CURRENT_THEME) == lyreAppTheme.toString()
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
              instance.setString(CURRENT_THEME, lyreAppTheme.toString());
              BlocProvider.of<ThemeBloc>(context)
              .dispatch(ThemeChanged(theme: lyreAppTheme));
            });
          },
        ),
      ));
    });
    return list;
  }
}
class SettingsTitleRow extends StatelessWidget {
  final String title;
  final Widget leading;

  const SettingsTitleRow({this.title, this.leading});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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