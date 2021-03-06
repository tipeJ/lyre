import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:lyre/widgets/CustomExpansionTile.dart';
import '../UploadUtils/ImgurAPI.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Resources/PreferenceValues.dart';

class PreferencesView extends StatefulWidget {
  PreferencesView({Key key}) : super(key: key);

  _PreferencesViewState createState() => _PreferencesViewState();
}
class _PreferencesViewState extends State<PreferencesView> with SingleTickerProviderStateMixin {

  Box box;
  bool advanced = false;

  @override
  void dispose() { 
    box.close();
    super.dispose();
  }

  Future<bool> _willPop() async {
    BlocProvider.of<LyreBloc>(context).add(SettingsChanged(settings: box));
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPop,
      child: Scaffold(
        body: FutureBuilder(
          future: Hive.openBox(BOX_SETTINGS_PREFIX + BlocProvider.of<LyreBloc>(context).state.currentUserName),
          builder: (context, snapshot){
            if (snapshot.hasData) {
              this.box = snapshot.data;
              blurLevel = (box.get(IMAGE_BLUR_LEVEL, defaultValue: IMAGE_BLUR_LEVEL_DEFAULT)).toDouble();
              return Container(
                padding: EdgeInsets.all(10.0),
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverAppBar(
                      expandedHeight: 125.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: Theme.of(context).canvasColor,
                      actions: <Widget>[
                        const Material(child: Center(child: Text('Advanced'))),
                        Switch(
                          value: advanced,
                          onChanged: (value){
                            setState(() {
                              advanced = value;
                            });
                          },
                        )
                      ],
                      title: Text('Settings'),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        CustomExpansionTile(
                          initiallyExpanded: true,
                          title: 'General',
                          showDivider: true,
                          children: _getGeneralSettings(context),
                          ),
                        CustomExpansionTile(
                          initiallyExpanded: true,
                          title: 'Submissions',
                          showDivider: true,
                          children: _getSubmissionSettings(context),
                          ),
                        CustomExpansionTile(
                          initiallyExpanded: true,
                          title: 'Comments',
                          showDivider: true,
                          children: _getCommentsSettings(context),
                        ),
                        CustomExpansionTile(
                          initiallyExpanded: true,
                          title: 'Filters',
                          showDivider: true,
                          children: _getFiltersSettings(context),
                        ),
                        CustomExpansionTile(
                          initiallyExpanded: true,
                          title: 'Media',
                          showDivider: true,
                          children: _getMediaSettings(context),
                        ),
                        CustomExpansionTile(
                          initiallyExpanded: false,
                          title: 'Interface',
                          showDivider: true,
                          children: _getInterfaceSettings(context),
                        ),
                      ]),
                    )
                  ],
                )
              );
            } else {
              return Container();
            }
          },
        )
      )
    );
  }
  List<Widget> _getGeneralSettings(BuildContext context) {
    return [
      _settingsWidget(
        children: [
          _homeOptionsColumn(box: box,)
        ],
        isAdvanced: false
      ),
      _settingsWidget(
        children: [
          _SettingsTitleRow(
            title: "Show Karma in Quick Menu",
            description: "Shows Comment and Link Karma in Submission List Quick menu next to the user name",
            leading: Checkbox(
              value: box.get(MENUSHEET_SHOW_KARMA, defaultValue: MENUSHEET_SHOW_KARMA_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(MENUSHEET_SHOW_KARMA, value);  
                });
              },)
          ),
        ],
        isAdvanced: true
      )
    ];
  }
  List<Widget> _getSubmissionSettings(BuildContext context){
    return [
      _settingsWidget(
        children: [
          WatchBoxBuilder(
            box: box,
            builder: (context, box){
              return _SettingsTitleRow(
                title: "Default Sorting Type",
                description: "Your Subreddit Submissions will by default take this value (Hot, Top, etc..)",
                leading: DropdownButton<String>(
                  value: box.get(SUBMISSION_DEFAULT_SORT_TYPE, defaultValue: SUBMISSION_DEFAULT_SORT_TYPE_DEFAULT),
                  items: sortTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    box.put(SUBMISSION_DEFAULT_SORT_TYPE, value);
                    setState(() {
                    });
                  },
                ),
              );
            },
          ),
          WatchBoxBuilder(
            box: box,
            builder: (context, box){
              return _SettingsTitleRow(
                title: "Default Sorting Time",
                description: "Your Subreddit Submissions will by default take this value when the sorting type is Time-Based (Top, Controversial)",
                leading: DropdownButton<String>(
                  value: box.get(SUBMISSION_DEFAULT_SORT_TIME, defaultValue: SUBMISSION_DEFAULT_SORT_TIME_DEFAULT),
                  items: sortTimes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    box.put(SUBMISSION_DEFAULT_SORT_TIME, value);
                  },
                )
              );
            },
          ),
          _SettingsTitleRow(
            title: "Auto-Load Posts",
            description: "Enables Never-Ending scrolling",
            leading: Checkbox(
              value: box.get(SUBMISSION_AUTO_LOAD, defaultValue: SUBMISSION_AUTO_LOAD_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(SUBMISSION_AUTO_LOAD, value);  
                });
              },)
          ),
          WatchBoxBuilder(
            box: box,
            builder: (context, box){
              return _SettingsTitleRow(
                title: "Post View Mode",
                description: "What form will the submissions cards take",
                leading: DropdownButton<PostView>(
                  value: box.get(SUBMISSION_VIEWMODE, defaultValue: SUBMISSION_VIEWMODE_DEFAULT),
                  items: PostView.values.map((PostView value) {
                    return DropdownMenuItem<PostView>(
                      value: value,
                      child: Text(value.toString().split('.')[1]),
                    );
                  }).toList(),
                  onChanged: (value) {
                    box.put(SUBMISSION_VIEWMODE, value);
                  },
                )
              );
            },
          ),
        
        ],
        isAdvanced: false
      ),
      _settingsWidget(
        children:[
          _SettingsTitleRow(
            title: "Reset Sorting When Refreshing Submission List",
            description: "Will refreshing Submission list or entering a submission list reset the Sorting params (Hot, Top, Time, etc..) to their default values (Can be set in the default Sorting Params settings)",
            leading: Checkbox(
              value: box.get(SUBMISSION_RESET_SORTING, defaultValue: SUBMISSION_RESET_SORTING_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(SUBMISSION_RESET_SORTING, value);
                });
              },)
          ),
          _SettingsTitleRow(
            title: "Reset PostView When Refreshing Submission List",
            description: "Will refreshing Submission list or entering a new Submission list reset PostView Setting to the default one)",
            leading: Checkbox(
              value: box.get(SUBMISSION_VIEWMODE_RESET, defaultValue: SUBMISSION_VIEWMODE_RESET_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(SUBMISSION_VIEWMODE_RESET, value);
                });
              },)
          ),
          _SettingsTitleRow(
            title: "Show Circle Around Preview Indicator",
            description: "When enabled, show a circle around the link indicator (video, image, etc..)",
            leading: Checkbox(
              value: box.get(SUBMISSION_PREVIEW_SHOWCIRCLE, defaultValue: SUBMISSION_PREVIEW_SHOWCIRCLE_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(SUBMISSION_PREVIEW_SHOWCIRCLE, value);
                });
              },)
          ),
          _SettingsTitleRow(
            title: "Legacy Submission Sorting",
            description: "When enabled, shows an older prototype of submissions filters. Takes less vertical space but was deprecated due to being too unfriendly towards smaller ppi displays",
            leading: Checkbox(
              value: box.get(LEGACY_SORTING_OPTIONS, defaultValue: LEGACY_SORTING_OPTIONS_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(LEGACY_SORTING_OPTIONS, value);
                });
              },)
          ),

        ],
        isAdvanced: true
      ),
      
    ];
  }
  List<Widget> _getCommentsSettings(BuildContext context){
    return [
      _settingsWidget(
        children: [
          WatchBoxBuilder(
            watchKeys: [COMMENTS_DEFAULT_SORT],
            box: box,
            builder: (context, box){
              return _SettingsTitleRow(
                title: "Default Comments Sort",
                description: "Default Sorting Params of Comments list",
                leading: DropdownButton<String>(
                  value: box.get(COMMENTS_DEFAULT_SORT, defaultValue: COMMENTS_DEFAULT_SORT_DEFAULT),
                  items: commentSortTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
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
            box: box,
            builder: (context, box){
              return _SettingsTitleRow(
                title: 'Precollapse Threads', 
                description: "Collapse all Comment threads to the top level comments by default",
                leading: Checkbox(
                  value: box.get(COMMENTS_PRECOLLAPSE, defaultValue: COMMENTS_PRECOLLAPSE_DEFAULT),
                  onChanged: (value){
                    setState(() {
                      box.put(COMMENTS_PRECOLLAPSE, value);
                    });
                  },)
              );
            },
          )
        ],
        isAdvanced: false
      ),
    ];
  }
  double blurLevel = 20.0;
  List<Widget> _getFiltersSettings(BuildContext context){
    return [
      _settingsWidget(
        children: [
          _SettingsTitleRow(
            title: 'Show NSFW Previews', 
            description: "When disabled, Lyre will automatically blur previews that contain NSFW content",
            leading: Checkbox(
              value: box.get(SHOW_NSFW_PREVIEWS, defaultValue: SHOW_NSFW_PREVIEWS_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(SHOW_NSFW_PREVIEWS, value);
                });
              },)
          ),
          _SettingsTitleRow(
            title: 'Show Spoiler Previews', 
            description: "When disabled, Lyre will automatically blur previews that contain spoilers",
            leading: Checkbox(
              value: box.get(SHOW_SPOILER_PREVIEWS, defaultValue: SHOW_SPOILER_PREVIEWS_DEFAULT),
              onChanged: (value){
                setState(() {
                  box.put(SHOW_SPOILER_PREVIEWS, value);
                });
              },)
          ),
        ],
        isAdvanced: false
      ),
      _settingsWidget(
        children: [
          Text('Blur level'),
          StatefulBuilder(
            builder: (context, setState){
              return WatchBoxBuilder(
                box: box,
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
        isAdvanced: true
      ),
      ListTile(
        title: const Text('Filter Blacklist'),
        onTap: () {
          Navigator.of(context).pushNamed('filters');
        },
        onLongPress: () => _showDescriptionDialog(context, "Filter Blacklist",
          "Which subreddits, users or domains are automatically filtered from listings (In the app side, the data will still be downloaded)"
        ),
      ),
      PostsProvider().isLoggedIn()
        ? ListTile(
          title: const Text('Global Community Filters'),
          onTap: () {
            Navigator.of(context).pushNamed('filters_global');
          },
          onLongPress: () => _showDescriptionDialog(context, "Global Community Filters",
            "Which subreddits are filtered from r/all in the Reddit side (These filters will also apply in browsers or other Reddit apps"
          ),
        )
        : null
    ].where((w) => notNull(w)).toList();
  }
  List<Widget> _getMediaSettings(BuildContext context){
    return [
      _settingsWidget(
        children: [
          _SettingsTitleRow(
            title: "Show Full Size Previews",
            description: "When enabled, shows the full-height images in large cards",
            leading: Checkbox(
              value: box.get(IMAGE_SHOW_FULLSIZE) ?? false,
              onChanged: (value){
                setState(() {
                  box.put(IMAGE_SHOW_FULLSIZE, value);
                });
            },)
          ),
          /*
          _SettingsTitleRow(
            title: "Enable Video Rotation",
            leading: Checkbox(
              value: box.get(VIDEO_ENABLE_ROTATION) ?? false,
              onChanged: (value){
                box.put(VIDEO_ENABLE_ROTATION, value);
            },)
          ),
          */
          _SettingsTitleRow(
            title: "Album Column Amount",
            description: "Set the amount of columns in grid image view",
            leading: OutlineButton(
              child: Text(MediaQuery.of(context).orientation == Orientation.portrait ? (box.get(ALBUM_COLUMN_AMOUNT_PORTRAIT) != null ? box.get(ALBUM_COLUMN_AMOUNT_PORTRAIT).toString() : 'Auto') : (box.get(ALBUM_COLUMN_AMOUNT_LANDSCAPE) != null ? box.get(ALBUM_COLUMN_AMOUNT_LANDSCAPE).toString() : 'Auto')),
              onPressed: () {
                _columnAmountPortrait = box.get(ALBUM_COLUMN_AMOUNT_PORTRAIT);
                _showAlbumColumnsDialog();
              },
            )
          ),
          _SettingsTitleRow(
            title: "Loop Videos",
            description: "When enabled, all videos will automatically start again after ending",
            leading: Checkbox(
              value: box.get(VIDEO_LOOP) ?? true,
              onChanged: (value){
                setState(() {
                  box.put(VIDEO_LOOP, value);
                });
            },)
          ),
          _SettingsTitleRow(
            title: "Auto-Mute Videos",
            description: "When enabled, all videos will automatically be muted at start",
            leading: Checkbox(
              value: box.get(VIDEO_AUTO_MUTE) ?? false,
              onChanged: (value){
                setState(() {
                  box.put(VIDEO_AUTO_MUTE, value);
                });
            },)
          ),
        ],
        isAdvanced: false
      ),
      _settingsWidget(
        children: [
          WatchBoxBuilder(
            watchKeys: [IMGUR_THUMBNAIL_QUALITY],
            box: box,
            builder: (context, box){
              return _SettingsTitleRow(
                title: "Imgur Thumbnail Quality",
                description: "Choose the quality in which imgur thumbnails are shown in album preview views",
                leading: DropdownButton<String>(
                  value: box.get(IMGUR_THUMBNAIL_QUALITY, defaultValue: IMGUR_THUMBNAIL_QUALITY_DEFAULT),
                  items: imgurThumbnailsQuality.keys.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    box.put(IMGUR_THUMBNAIL_QUALITY, value);
                  },
                )
              );
            },
          ),
        ],
        isAdvanced: true
      ),
    ];
  }
  List<Widget> _getInterfaceSettings(BuildContext context){
    return [
      _settingsWidget(
        isAdvanced: false,
        children: [
          InkWell(
            child: Container(
              padding: const EdgeInsets.only(
                left: 5.0,
                top: 10.0,
                bottom: 10.0
              ),
              child: const Text('Themes'),
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ThemeView()));
            },
          )
        ]
      )
    ];
  }
  Widget _settingsWidget({@required List<Widget> children, @required  bool isAdvanced}){
    return Visibility(
      child: Column(children: children,),
      visible: isAdvanced == advanced,
    );
  }

  int _columnAmountPortrait;
  int _columnAmountLandscape;
  Widget _columnIndicators(int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(amount, (i) => Container(
        padding: EdgeInsets.symmetric(horizontal: 1.0),
        width: 225 / amount,
        height: 225 / amount,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black54)
        ),
        child: Center(child: Icon(Icons.image),),
    )),);
  }
  void _showAlbumColumnsDialog() {
    final _tabController = TabController(vsync: this, length: 2);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
             return AlertDialog(
              title: const Text('Amount of Columns'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TabBar(
                    controller: _tabController,
                    tabs: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3.5),
                        child: Text('Portrait'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 3.5),
                        child: Text('Landscape'),
                      ),
                    ],
                  ),
                  TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(children: <Widget>[
                            const Text('Select Automatically'),
                            Checkbox(
                              value: _columnAmountPortrait == null,
                              onChanged: (bool newValue) {
                                setState(() {
                                  _columnAmountPortrait = newValue ? null : 3;
                                });
                              },
                            )
                          ],),
                          _columnAmountPortrait != null
                            ? _columnIndicators(_columnAmountPortrait)
                            : null,
                          _columnAmountPortrait != null
                            ? Slider(
                                divisions: 5,
                                min: 2,
                                max: 7,
                                onChanged: (double newValue) {
                                  setState(() {
                                    _columnAmountPortrait = newValue.round(); 
                                  });
                                },
                                value: _columnAmountPortrait == null ? 3.0 : _columnAmountPortrait.toDouble(),
                              )
                            : null,
                        ].where((w) => notNull(w)).toList(),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(children: <Widget>[
                            const Text('Select Automatically'),
                            Checkbox(
                              value: _columnAmountLandscape == null,
                              onChanged: (bool newValue) {
                                setState(() {
                                  _columnAmountLandscape = newValue ? null : 3;
                                });
                              },
                            )
                          ],),
                          _columnAmountLandscape != null
                            ? _columnIndicators(_columnAmountLandscape)
                            : null,
                          _columnAmountLandscape != null
                            ? Slider(
                                divisions: 5,
                                min: 2,
                                max: 7,
                                onChanged: (double newValue) {
                                  setState(() {
                                    _columnAmountLandscape = newValue.round(); 
                                  });
                                },
                                value: _columnAmountLandscape == null ? 3.0 : _columnAmountLandscape.toDouble(),
                              )
                            : null,
                        ].where((w) => notNull(w)).toList(),
                      )
                    ],
                  )
                ],
              ),
              actions: <Widget>[
                OutlineButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                OutlineButton(
                  child: const Text('OK'),
                  onPressed: () {
                    box.put(ALBUM_COLUMN_AMOUNT_PORTRAIT, _columnAmountPortrait);
                    box.put(ALBUM_COLUMN_AMOUNT_LANDSCAPE, _columnAmountLandscape);
                    Navigator.pop(context);
                  },
                )
              ],
            );
          },
        );
       
      }
    );
  }
}

void _showDescriptionDialog(BuildContext context, String title, String description) => showDialog(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(title),
    titlePadding: const EdgeInsets.all(12.0),
    children: <Widget>[Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0), child: Text(description)
  )],)
);

/// Widget for displaying Preferences Options. Will show a dialog with
/// [description] text when the title Text is long-pressed. Leading 
/// Widget will be shown last, while the title is always expanded.
class _SettingsTitleRow extends StatelessWidget {
  const _SettingsTitleRow({@required this.title, @required this.leading, @required this.description}
  ):  assert(title != null),
      assert(leading != null),
      assert(description != null);

  final Widget leading;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: leading,
      onLongPress: () => _showDescriptionDialog(context, title, description),
    );
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(title),
            ),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(title),
                  titlePadding: const EdgeInsets.all(12.0),
                  children: <Widget>[Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0),child: Text(description)
                )],)
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 5.0),
          child: leading,
        )
      ],
    );
  }
}

/// Widget for displaying options for Home Page Customization 
/// (Includes expanding setting for configuring custom home subreddit)
class _homeOptionsColumn extends StatefulWidget {
  final Box box;
  _homeOptionsColumn({this.box, Key key}) : super(key: key);

  @override
  __homeOptionsColumnState createState() => __homeOptionsColumnState();
}

class __homeOptionsColumnState extends State<_homeOptionsColumn> with SingleTickerProviderStateMixin{
  
  AnimationController _customHomeExpansionController;

  @override
  void initState() { 
    super.initState();
    _customHomeExpansionController = AnimationController(vsync: this, duration: Duration(milliseconds: 200), value: widget.box.get(HOME, defaultValue: HOME_DEFAULT) == _homeOptions[3] ? 1.0 : 0.0);
    _customHomeExpansionController.addListener(() {
      setState((){});
    });
  }

  @override
  void dispose() { 
    _customHomeExpansionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
       children: <Widget>[
         _SettingsTitleRow(
            title: "Home",
            description: "First community that opens when you start the app. Can also be quickly accessed via double-tapping the bottom appbar",
            leading: DropdownButton<String>(
              value: widget.box.get(HOME, defaultValue: HOME_DEFAULT),
              items: _homeOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                widget.box.put(HOME, value);
                setState(() {
                  if (value == _homeOptions[3]) {
                    _customHomeExpansionController.forward();
                  } else if (_customHomeExpansionController.value != 0.0) {
                    _customHomeExpansionController.reverse();
                  }
                });
              },
            ),
          ),
          SizeTransition(
            sizeFactor: _customHomeExpansionController,
            axis: Axis.vertical,
            child: WatchBoxBuilder(
              box: widget.box,
              builder: (context, box){
                return Padding(
                  padding: EdgeInsets.all(5.0),
                  child: TextFormField(
                    //TODO: Add option for frontpage, popular etc for home subreddit
                    initialValue: box.get(SUBREDDIT_HOME),
                    decoration: InputDecoration(
                      prefixText: "r/",
                      labelText: 'Home Subreddit'
                    ),   
                    onFieldSubmitted: (value) {
                      box.put(SUBREDDIT_HOME, value);
                    },               
                  )
                );
              },
            ),
          )
       ],
    );
  }
}

List<String> _homeOptions = const [
  "Frontpage",
  "Popular",
  "All",
  "Custom Subreddit"
];