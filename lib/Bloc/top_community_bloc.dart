import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:lyre/Models/models.dart';
import 'package:lyre/Resources/resources.dart';
import 'package:meta/meta.dart';

part 'top_community_event.dart';
part 'top_community_state.dart';

class TopCommunityBloc extends Bloc<TopCommunityEvent, TopCommunityState> {
  @override
  TopCommunityState get initialState => TopCommunityState(
    loadingState: LoadingState.Inactive,
    category: "null",
    communities: const []
  );

  @override
  Stream<TopCommunityState> mapEventToState(
    TopCommunityEvent event,
  ) async* {
    if (event is ChangeCategory) {
      yield TopCommunityState(
        loadingState: LoadingState.Refreshing,
        category: event.category,
        communities: const []
      );
      final response = await PostsProvider().client.post(
        "https://gql.reddit.com/", 
        body: json.encode({
          'id' : "9e9ef4c82a00",
          'variables' : {
            'categoryId' : "${redditTopCommunitiesCategories[event.category]}",
            'isOnlyModIncluded' : false,
            'first' : 5
          }
        }),
        headers: {
          "x-reddit-loid" : "00000000000012wd3r.2.1479454171976.Z0FBQUFBQmVRc3FSbUxCVWl0eE9GaWF2eUxDSS1uQmdvSU1hSnBZMndaYlVPNFBDcDdOMVJGWHZlc2hIUnphNi1NZDk3eTBPVW5KWTkyZWtCT0ZNcF9MQXk3T0trY1BhZnV5R2xuTzc1ckwwcXdodHhiN29SdDlwTExvS1R0NV9XSWVyZXgxUnVZV00",
          "x-reddit-session" : "AVPS2jOehxDLlTx8W4.0.1582128228833.Z0FBQUFBQmVUVnhraUprUTc1RVpzbU1rNTlpb2QxOENYM1Q0ekRsVVBJMHFfSVBac0ktTDBKenZqMzB5d3JEUF9KQ2NzZVdPdTdGcC1jU0J3c056MjVhdUg3OFlibFlwX2dZbzhEdF9hWlN6U01RZnU1ZXhVZnVnSDZpdWptOGJaeGtjWFJzV3ZCeDM",
          "request_timestamp" : DateTime.now().toUtc().millisecondsSinceEpoch.toString(),
          "authorization": "Bearer -OXmVMtLmn1m6VYJuC7UE1c96AoE",
          "user-agent" : "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.92 Safari/537.36 Vivaldi/2.9.1705.38",
          "content-type": "application/json",
          "origin": "https://www.reddit.com",
          "referer": "https://www.reddit.com/",
          "sec-fetch-mode": "cors",
          "sec-fetch-site": "same-site"
        },
        encoding: Encoding.getByName("gzip")
      );
      final items = _convertResponseJson(response.body);
      yield TopCommunityState(
        loadingState: LoadingState.Inactive,
        category: event.category,
        communities: items
      );
    }
  }
  static List<TopCommunity> _convertResponseJson(String rawJson) {
    final decodedJson = json.decode(rawJson);
    final List<dynamic> subredditList = decodedJson['data']['subredditLeaderboard']['edges'];
    List<TopCommunity> list = [];
    subredditList.forEach((subJson) => list.add(TopCommunity.fromJson(subJson['node'])));
    return list;
  }
}
