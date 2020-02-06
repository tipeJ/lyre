import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lyre/Bloc/bloc.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'package:lyre/Themes/bloc/bloc.dart';
import 'package:lyre/screens/screens.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:transparent_image/transparent_image.dart';

class LyreHeader extends StatelessWidget {
  final PostsState state;
  const LyreHeader({@required this.state, Key key}) : super(key: key);

  static const _avatarRadius = 30.0;
  static const _boxHeight = 80.0;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        children: <Widget>[
          Column(children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: _boxHeight,
              child: state.subreddit != null && state.subreddit.mobileHeaderImage != null
                ? FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: AdvancedNetworkImage(
                      state.subreddit.mobileHeaderImage.toString(),
                      useDiskCache: true,
                      cacheRule: const CacheRule(maxAge: Duration(days: 3)),
                    ),
                    fit: BoxFit.cover
                  )
                : Container() // TODO: Placeholder image,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: _boxHeight,
              color: Theme.of(context).cardColor,
              child: Column(children: <Widget>[
                Container(
                  height: _avatarRadius + 5.0,
                ),
                Text(state.getSourceString()),
                const SizedBox(height: 5.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _getTargetInfo(context)
                )
              ],)
            )
          ]),
          Positioned(
            top: _boxHeight - _avatarRadius,
            child: Container(
              width: MediaQuery.of(context).size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _getAvatarRow(context) 
              )
            ),
          )
        ],
      )
    );
  }
  List<Widget> _getAvatarRow(BuildContext context) {
    if (state.contentSource == ContentSource.Subreddit && state.subreddit != null) {
      return [
        Container(
          width: _avatarRadius * 1.5,
          height: _avatarRadius * 1.5,
          child: RawMaterialButton(
            shape: const CircleBorder(),
            elevation: 5.0,
            fillColor: Theme.of(context).primaryColor,
            child: Container(
              child: BlocBuilder<LyreBloc, LyreState>(
                builder: (context, lyreState) {
                  if (lyreState.isSubscribed(state.target)) {
                    return Icon(Icons.favorite, color: Theme.of(context).accentColor);
                  }
                  return const Icon(Icons.favorite_border);
                },
              )
            ),
            onPressed: (){
              BlocProvider.of<LyreBloc>(context).add(ChangeSubscription(subreddit: state.target));
            },
          ),
        ),
        CircleAvatar(
          maxRadius: _avatarRadius,
          minRadius: _avatarRadius,
          backgroundColor: Theme.of(context).cardColor,
          backgroundImage: AdvancedNetworkImage(
            state.subreddit.iconImage != null
              ? state.subreddit.iconImage.toString()
              : "https://icons-for-free.com/iconfiles/png/512/reddit+website+icon-1320168605279647340.png",
            useDiskCache: true,
            cacheRule: const CacheRule(maxAge: Duration(days: 27)),
          ),
        ),
        Container(
          width: _avatarRadius * 1.5,
          height: _avatarRadius * 1.5,
          child: RawMaterialButton(
            shape: const CircleBorder(),
            elevation: 5.0,
            fillColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.info_outline),
            onPressed: (){
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ];
    } else if (state.contentSource == ContentSource.Redditor) {
      return [
        // TODO: Replace this with "Friend" - Button
        Container(
          width: _avatarRadius * 1.5,
          height: _avatarRadius * 1.5,
          child: RawMaterialButton(
            shape: const CircleBorder(),
            elevation: 5.0,
            fillColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.trending_up),
            onPressed: () async {
              final trendingSubs = await PostsProvider().getTrendingSubreddits();
              Scaffold.of(context).showBottomSheet((context) => TrendingScreen(data: trendingSubs));
            },
          ),
        ),
        CircleAvatar(
          maxRadius: _avatarRadius,
          minRadius: _avatarRadius,
          backgroundColor: Theme.of(context).cardColor,
          backgroundImage: AdvancedNetworkImage(
            state.redditor.data["icon_img"],
            useDiskCache: true,
            cacheRule: const CacheRule(maxAge: Duration(days: 3)),
          ),
        ),
        Container(
          width: _avatarRadius * 1.5,
          height: _avatarRadius * 1.5,
          child: RawMaterialButton(
            shape: const CircleBorder(),
            elevation: 5.0,
            fillColor: Theme.of(context).primaryColor,
            child: const Icon(MdiIcons.help),
            onPressed: (){
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) => RedditHelpScreen()));
            },
          ),
        ),
      ];
    } else {
      return [
        Container(
          width: _avatarRadius * 1.5,
          height: _avatarRadius * 1.5,
          child: RawMaterialButton(
            shape: const CircleBorder(),
            elevation: 5.0,
            fillColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.trending_up),
            onPressed: () async {
              PreviewCall().callback.preview("https://watch.redd.it/hls/889e6fe7-14c7-4bec-a388-b9c60d45a3eb/index.m3u8");
              final trendingSubs = await PostsProvider().getTrendingSubreddits();
              Scaffold.of(context).showBottomSheet((context) => TrendingScreen(data: trendingSubs));
            },
          ),
        ),
        CircleAvatar(
          maxRadius: _avatarRadius,
          minRadius: _avatarRadius,
          backgroundColor: Theme.of(context).cardColor,
          backgroundImage: AdvancedNetworkImage(
            "https://icons-for-free.com/iconfiles/png/512/reddit+website+icon-1320168605279647340.png",
            useDiskCache: true,
            cacheRule: const CacheRule(maxAge: Duration(days: 27)),
          ),
        ),
        Container(
          width: _avatarRadius * 1.5,
          height: _avatarRadius * 1.5,
          child: RawMaterialButton(
            shape: const CircleBorder(),
            elevation: 5.0,
            fillColor: Theme.of(context).primaryColor,
            child: const Icon(MdiIcons.help),
            onPressed: (){
              Navigator.of(context).push(CupertinoPageRoute(builder: (context) => RedditHelpScreen()));
            },
          ),
        ),
      ];
    }
  }
  List<Widget> _getTargetInfo(BuildContext context) {
    if (state.contentSource == ContentSource.Subreddit && notNull(state.subreddit)) {
      return [
        Text(
          "${state.subreddit.data["subscribers"].toString()} Readers",
          style: Theme.of(context).textTheme.body2,
        ),
        Text(
          "${state.subreddit.data["accounts_active"].toString()} Online",
          style: Theme.of(context).textTheme.body2,
        )
      ];
    } else if (state.contentSource == ContentSource.Redditor && notNull(state.redditor)) {
      return [
        Text(
          "${state.redditor.commentKarma.toString()} Comment Karma",
          style: Theme.of(context).textTheme.body2,
        ),
        Text(
          "${state.redditor.linkKarma.toString()} Link Karma",
          style: Theme.of(context).textTheme.body2,
        )
      ];
    }
    return const [];
  }
}
class LyreSliverAppBar extends StatelessWidget {
  final PostsState state;
  const LyreSliverAppBar({@required this.state, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 5.0),
      sliver: SliverAppBar(
        expandedHeight: 125.0,
        floating: false,
        pinned: false,
        backgroundColor: Theme.of(context).canvasColor,
        actions: [Container()],
        automaticallyImplyLeading: false,
        flexibleSpace: FlexibleSpaceBar(
          centerTitle: false,
          titlePadding: const EdgeInsets.only(
            left: 10.0,
            bottom: 5.0
          ),
          collapseMode: CollapseMode.parallax,
          background: state.subreddit != null && state.subreddit.mobileHeaderImage != null
              ? FadeInImage(
                  placeholder: MemoryImage(kTransparentImage),
                  image: AdvancedNetworkImage(
                    state.subreddit.headerImage.toString(),
                    useDiskCache: true,
                    cacheRule: const CacheRule(maxAge: Duration(days: 3)),
                  ),
                  fit: BoxFit.cover
                )
              : Container(), // TODO: Placeholder image
          title: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 1.5),
            child: Text(
              // TODO: Fix this shit (can't add / without causing a new line automatically)
              state.getSourceString(prefix: false),
              softWrap: true,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
      )))
    );
  }
}