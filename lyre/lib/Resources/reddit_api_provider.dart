import 'dart:async';
import 'package:http/http.dart' show Client;
import 'dart:convert';
import '../Models/item_model.dart';
import '../Models/Comment.dart';
import '../Models/Subreddit.dart';
import 'globals.dart';
import 'package:draw/draw.dart';

class PostsProvider {
  Client client = Client();
  final _apiKey = 'your_api_key';

  Future<ItemModel> fetchPostsList(bool loadMore) async {
    print("Posts fetched");
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = (loadMore) ?
      await client.get("${BASE_URL}${currentSubreddit}/.json?count=$currentCount&after=t3_$lastPost", headers: headers)
        : await client.get("${BASE_URL}${currentSubreddit}/.json", headers: headers);
    if (response.statusCode == 200) {
      print("succ");
      // If the call to the server was successful, parse the JSON
      return ItemModel.fromJson(json.decode(response.body)["data"]["children"]);
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load post');
    }
  }

  Future<Reddit> getRed() async {
    return await Reddit.createReadOnlyInstance();
  }

  Future<ItemModel> fetchUserContent() async {
    Reddit r = await getRed();
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var v = await r.subreddit(currentSubreddit).hot().toList();
    var f = await r.subreddit(currentSubreddit).hot(params: headers);

    return ItemModel.fromApi(v);
  }
  Future<CommentM> fetchCommentsList() async {
    print('comments fetched');
    Map<String, String> headers = new Map<String, String>();
    headers["before"] = "0";

    var response = await client.get("${COMMENTS_BASE_URL}${currentPostId}/.json", headers: headers);
    if(response.statusCode == 200){
      print('comments succ');
      return CommentM.fromJson(json.decode(response.body)[1]["data"]["children"]);
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<SubredditM> fetchSubReddits(String query) async{
    query.replaceAll(" ", "+");
    print('Subreddits fetched');
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await client.get("${SUBREDDITS_BASE_URL}search.json?q=${query}&include_over_18=on", headers: headers);
    if(response.statusCode == 200){
      print('successfully fetched subreddits');
      return SubredditM.fromJson(json.decode(response.body)["data"]["children"]);
    } else {
      throw Exception('Failed to load subreddits');
    }
  }
}