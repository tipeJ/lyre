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
    var response = await r.get("/api/morechildren.json", params: headers);
    
    var b2 = CommentM.fromJson2(response, r);
    return b2;
  }

  Future<ItemModel> fetchUserContent(String typeFilter, String timeFilter, bool loadMore) async {
    Reddit r = await getRed();
    Map<String, String> headers = new Map<String, String>();

    if(loadMore)headers["after"]="t3_$lastPost";

    headers["limit"] = perPage.toString();
    if(typeFilter == "hot" || typeFilter == "new" || typeFilter == "rising"){
      timeFilter = "";
      //This is to ensure that no unfitting timefilters get bundled with specific-time typefilters.
    }
    if(timeFilter == ""){
      switch (typeFilter){
            case "hot":
              var v = await r.subreddit(currentSubreddit).hot(params: headers).toList();
              return ItemModel.fromApi(v);
            case "new":
              var v = await r.subreddit(currentSubreddit).newest(params: headers).toList();
              return ItemModel.fromApi(v);
            case "rising":
              var v = await r.subreddit(currentSubreddit).rising(params: headers).toList();
              return ItemModel.fromApi(v);
        }
    }else{
      var filter = parseTimeFilter(timeFilter);
      switch (typeFilter){
            case "controversial":
              var v = await r.subreddit(currentSubreddit).controversial(timeFilter: filter, params: headers).toList();
              return ItemModel.fromApi(v);
            case "top":
              var v = await r.subreddit(currentSubreddit).top(timeFilter: filter, params: headers).toList();
              return ItemModel.fromApi(v);
        }
    }
    
    return null;
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

  Future<SubredditM> fetchSubReddits(String query) async{
    query.replaceAll(" ", "+");
    print('Subreddits fetched');
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await client.get("${SUBREDDITS_BASE_URL}search.json?q=r/${query}&include_over_18=on", headers: headers);
    if(response.statusCode == 200){
      print('successfully fetched subreddits');
      return SubredditM.fromJson(json.decode(response.body)["data"]["children"]);
    } else {
      throw Exception('Failed to load subreddits');
    }
  }

  TimeFilter parseTimeFilter(String query){
    switch (query) {
      case "hour":
        return TimeFilter.hour;
      case "24h":
        return TimeFilter.day;
      case "week":
        return TimeFilter.week;
      case "month":
        return TimeFilter.month;
      case "year":
        return TimeFilter.year;
      case "all time":
        return TimeFilter.all;
      default:
      //SHOULD NOT HAPPEN:
        return TimeFilter.day;
    }
  }
}