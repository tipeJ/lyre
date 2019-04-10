import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show Client;
import 'dart:convert';
import '../Models/item_model.dart';
import '../Models/Comment.dart';
import '../Models/Commenter.dart';
import '../Models/Subreddit.dart';
import 'globals.dart';
import 'package:draw/draw.dart';
import 'package:uuid/uuid.dart';

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
    return await Reddit.createReadOnlyInstance(
      userAgent: "$appName $appVersion by u/tipezuke",
      clientId: "6sQY26tkKTP99w",
      clientSecret: "Kpt1s3sUt2GMYhEBqLNZVPkeSW8",
    );
  }
  Future<CommentM> getC2(String ids, String fullname) async {
    
    print('2comment ' + ids + ' fetched');
    Map<String, String> headers = new Map<String, String>();
      headers["children"] = ids;
      headers["link_id"] = "t3_$fullname";
      headers["sort"] = "confidence";
      headers["limit_children"] = "true";
      headers["api_type"] = "json";
    var r = await getRed();
    var x = await r.post("/api/morechildren", headers);
    var x2 = await r.get("/api/morechildren.json", params: headers);
    
    var b2 = CommentM.fromJson2(x2, r);
    return b2;
    try{
      
    }catch(e){
      print(e);
      return null;
    }
  }
  Future<CommentM> getC(String id) async {
    print('comment ' + id + ' fetched');
    Map<String, String> headers = new Map<String, String>();



    var response = await client.get("https://www.reddit.com/api/info.json?id=t1_" + id, headers: headers);
    if(response.statusCode == 200){
      var v = CommentM.fromJson(json.decode(response.body)["data"]["children"]);
      print('Hands Up for successful comment fetch');
      return v;
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<ItemModel> fetchUserContent() async {
    Reddit r = await getRed();
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var v = await r.subreddit(currentSubreddit).hot(params: headers).toList();
    for(int i = 0; i < v.length; i++){
      
    }
    

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
      throw Exception('Failed to load comments, statuscode: ' + response.statusCode.toString());
    }
  }
  Future<Commenter> fetchCommentsListAPI() async {
    print('comments fetched from API');
    Map<String, String> headers = new Map<String, String>();
    headers["before"] = "0";

    var r = await getRed();

    var sub = await SubmissionRef.withID(r, currentPostId).fetch();
    var forest = await CommentForest(sub);
    var comments = await forest.comments;
    return Commenter.fromApi(comments);
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