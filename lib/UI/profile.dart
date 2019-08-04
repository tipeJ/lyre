import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:draw/draw.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';
import 'postInnerWidget.dart';
import '../Blocs/posts_bloc.dart';
import '../Resources/globals.dart';
import '../Models/item_model.dart';

class UserView extends StatefulWidget {
  PostsBloc bloc;
  final String fullname;

  UserView(this.fullname);
  @override
  _UserViewState createState() => _UserViewState(fullname);
}

class _UserViewState extends State<UserView> {
  final String fullname;
  _UserViewState(this.fullname);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(
          top: 8.0,
          left: 8.0,
          right: 8.0
        ),
        child: FutureBuilder(
          future: PostsProvider().getRedditor(fullname),
          builder: (context, snapshot){
            if(snapshot.connectionState == ConnectionState.done){
                var data = snapshot.data;
                if(data is Redditor){
                  return StreamBuilder(
                    stream: bloc.allPosts,
                    builder: (context, AsyncSnapshot<ItemModel> snapshot) {
                    if (snapshot.hasData) {
                      return null;
                    } else if (snapshot.hasError) {
                      return Text(snapshot.error.toString());
                    }
                    return Center(child: CircularProgressIndicator());
                  },
                  );
                }else{
                  print('smth went horribly wrong here');
                }
              }else{ 
                return Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(),
                  ),
                );
              }
          }
        )
      ),
    );
  }
  Widget getSpaciousUserColumn(Redditor redditor){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Container(
          child: ClipOval(
            child: Image(
              image: AdvancedNetworkImage(
                redditor.data['icon_img'],
                useDiskCache: true,
                cacheRule: CacheRule(maxAge: const Duration(days: 7))
              ),
            ),
          ),
          width: 120,
          height: 120,
        ),
        Divider(),
        Text(
          'u/${redditor.fullname}',
          style: TextStyle(
            fontSize: 25.0,
          ),
          ),
        Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text('Post karma: ${redditor.linkKarma}',
              style: TextStyle(color: Colors.white60)),
            Text('Comment karma: ${redditor.commentKarma}',
              style: TextStyle(color: Colors.white60))
          ],
        )
      ],
    );
  }
}