import 'dart:async';
import 'package:http/http.dart' show Client;
import 'dart:convert';
import '../Models/item_model.dart';
import '../Models/Comment.dart';
import 'globals.dart';
import 'package:draw/draw.dart';

class PostsProvider {
  Client client = Client();
  final _apiKey = 'your_api_key';

  Future<ItemModel> fetchPostsList() async {
    print("entered");
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await client.get("${BASE_URL}${currentSubreddit}/.json", headers: headers);
    if (response.statusCode == 200) {
      print("succ");
      // If the call to the server was successful, parse the JSON
      return ItemModel.fromJson(json.decode(response.body)["data"]["children"]);
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load post');
    }
  }

  Future<CommentM> fetchCommentsList() async {
    print('comments fetched');
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await client.get("${COMMENTS_BASE_URL}${currentPostId}/.json", headers: headers);
    if(response.statusCode == 200){
      print('comments succ');
      return CommentM.fromJson(json.decode(response.body)[1]["data"]["children"]);
    } else {
      throw Exception('Failed to load comments');
    }
  }
}