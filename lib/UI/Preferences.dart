import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/UI/CustomExpansionTile.dart';
import '../Themes/themes.dart';
import '../Themes/bloc/theme_bloc.dart';
import '../Themes/bloc/theme_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Resources/PreferenceValues.dart';

class PreferencesView extends StatefulWidget {
  PreferencesView({Key key}) : super(key: key);

  _PreferencesViewState createState() => _PreferencesViewState();
}
class _PreferencesViewState extends State<PreferencesView> {

  Box box;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Hive.openBox('settings'),
        builder: (context, snapshot){
          if (snapshot.hasData) {
            this.box = snapshot.data;
            blurLevel = (box.get(IMAGE_BLUR_LEVEL) ?? 20.0).toDouble();
            return Container(
              padding: EdgeInsets.all(10.0),
              child: ListView(
                children: <Widget>[
                  CustomExpansionTile(
                    initiallyExpanded: true,
                    title: 'Submissions',
                    children: getSubmissionSettings(context),
                  ),
                  CustomExpansionTile(
                    initiallyExpanded: true,
                    title: 'Comments',
                    children: getCommentsSettings(context),
                  ),
                  CustomExpansionTile(
                    initiallyExpanded: true,
                    title: 'Filters',
                    children: getFiltersSettings(context),
                  ),
                  CustomExpansionTile(
                    initiallyExpanded: true,
                    title: 'Media',
                    children: getMediaSettings(context),
                  ),
                  CustomExpansionTile(
                    initiallyExpanded: false,
                    title: 'Themes',
                    children: getThemeSettings(context),
                  ),
                ],
              )
            );
          } else {
            return Container();
          }
        },
      )
    );
  }
  List<Widget> getSubmissionSettings(BuildContext context){
    return [
      WatchBoxBuilder(
        box: Hive.box('settings'),
        builder: (context, box){
          return SettingsTitleRow(
            title: "Default Sorting Type",
            leading: new DropdownButton<String>(
              value: box.get(SUBMISSION_DEFAULT_SORT_TYPE) ?? sortTypes[0],
              items: sortTypes.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (value) {
                box.put(SUBMISSION_DEFAULT_SORT_TYPE, value);
                setState(() {
                });
              },
            )
          );
        },
      ),
      WatchBoxBuilder(
        box: Hive.box('settings'),
        builder: (context, box){
          return SettingsTitleRow(
            title: "Default Sorting Time",
            leading: new DropdownButton<String>(
              value: box.get(SUBMISSION_DEFAULT_SORT_TIME) ?? sortTimes[1],
              items: sortTimes.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (value) {
                box.put(SUBMISSION_DEFAULT_SORT_TIME, value);
              },
            )
          );
        },
      ),
      SettingsTitleRow(
        title: "Reset Sorting When Refreshing Submission List",
        leading: Switch(
          value: box.get(SUBMISSION_RESET_SORTING) ?? true,
          onChanged: (value){
            box.put(SUBMISSION_RESET_SORTING, value);
          },)
      ),
      SettingsTitleRow(
        title: "Auto-Load Posts",
        leading: Switch(
          value: box.get(SUBMISSION_AUTO_LOAD) ?? false,
          onChanged: (value){
            box.put(SUBMISSION_AUTO_LOAD, value);
          },)
      ),
      SettingsTitleRow(
        title: "Show Circle Around Preview Indicator",
        leading: Switch(
          value: box.get(SUBMISSION_PREVIEW_SHOWCIRCLE) ?? true,
          onChanged: (value){
            box.put(SUBMISSION_PREVIEW_SHOWCIRCLE, value);
          },)
      ),
      WatchBoxBuilder(
        box: Hive.box('settings'),
        builder: (context, box){
          return SettingsTitleRow(
            title: "Post View Mode",
            leading: new DropdownButton<PostView>(
              value: box.get(SUBMISSION_VIEWMODE) ?? PostView.Compact,
              items: PostView.values.map((PostView value) {
                return new DropdownMenuItem<PostView>(
                  value: value,
                  child: new Text(value.toString().split('.')[1]),
                );
              }).toList(),
              onChanged: (value) {
                box.put(SUBMISSION_VIEWMODE, value);
              },
            )
          );
        },
      ),
    ];
  }
  List<Widget> getCommentsSettings(BuildContext context){
    return [
      WatchBoxBuilder(
        box: Hive.box('settings'),
        builder: (context, box){
          return SettingsTitleRow(
            title: "Default Comments Sort",
            leading: new DropdownButton<String>(
              value: box.get(COMMENTS_DEFAULT_SORT) ?? commentSortTypes[1],
              items: commentSortTypes.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
              onChanged: (value) {
                box.put(COMMENTS_DEFAULT_SORT, value);
              },
            )
          );
        },
      ),
      WatchBoxBuilder(
        box: Hive.box('settings'),
        builder: (context, box){
          return SettingsTitleRow(
            title: 'Precollapse Threads', 
            leading: Switch(
              value: box.get(COMMENTS_PRECOLLAPSE) ?? false,
              onChanged: (value){
                box.put(COMMENTS_PRECOLLAPSE, value);
              },)
          );
        },
      )
      
    ];
  }
  double blurLevel = 20.0;
  List<Widget> getFiltersSettings(BuildContext context){
    return [
      SettingsTitleRow(
        title: 'Show NSFW Previews', 
        leading: Switch(
          value: box.get(SHOW_NSFW_PREVIEWS) ?? false,
          onChanged: (value){
            box.put(SHOW_NSFW_PREVIEWS, value);
          },)
      ),
      SettingsTitleRow(
        title: 'Show Spoiler Previews', 
        leading: Switch(
          value: box.get(SHOW_SPOILER_PREVIEWS) ?? false,
          onChanged: (value){
            box.put(SHOW_SPOILER_PREVIEWS, value);
          },)
      ),
      Column(
        children: <Widget>[
          Text('Blur level'),
          StatefulBuilder(
            builder: (context, setState){
              return WatchBoxBuilder(
                box: Hive.box('settings'),
                builder: (context, box){
                  return Slider(
                    min: 5.0,
                    max: 100.0,
                    value: blurLevel,
                    onChanged: (double newValue){
                      setState(() {
                        blurLevel = newValue;
                      });
                    },
                    onChangeEnd: (double value){
                      box.put(IMAGE_BLUR_LEVEL, value >= 5.0 && value <= 100.0 ? value.round() : 20);
                    },
                  );
                },
              );
            },
          )
        ],
      )
    ];
  }
  List<Widget> getMediaSettings(BuildContext context){
    return [
      /*
      SettingsTitleRow(
        title: "Enable Image Rotation",
        leading: Switch(
          value: box.get(IMAGE_ENABLE_ROTATION) ?? false,
          onChanged: (value){
            box.put(IMAGE_ENABLE_ROTATION, value);
        },)
      ),
      */
      SettingsTitleRow(
        title: "Show Full Size Previews",
        leading: Switch(
          value: box.get(IMAGE_SHOW_FULLSIZE) ?? false,
          onChanged: (value){
            box.put(IMAGE_SHOW_FULLSIZE, value);
        },)
      ),
      /*
      SettingsTitleRow(
        title: "Enable Video Rotation",
        leading: Switch(
          value: box.get(VIDEO_ENABLE_ROTATION) ?? false,
          onChanged: (value){
            box.put(VIDEO_ENABLE_ROTATION, value);
        },)
      ),
      */
      SettingsTitleRow(
        title: "Loop Videos",
        leading: Switch(
          value: box.get(VIDEO_LOOP) ?? true,
          onChanged: (value){
            box.put(VIDEO_LOOP, value);
        },)
      ),
       SettingsTitleRow(
        title: "Auto-Mute Videos",
        leading: Switch(
          value: box.get(VIDEO_AUTO_MUTE) ?? false,
          onChanged: (value){
            box.put(VIDEO_AUTO_MUTE, value);
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
          border: box.get(CURRENT_THEME) == lyreAppTheme.toString()
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
            box.put(CURRENT_THEME, lyreAppTheme.toString());
            BlocProvider.of<ThemeBloc>(context).add(ThemeChanged(theme: lyreAppTheme));
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