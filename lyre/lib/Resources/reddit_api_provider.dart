import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' show Client;
import 'dart:convert';
import '../Models/item_model.dart';
import '../Models/Comment.dart';
import '../Models/Subreddit.dart';
import '../Models/User.dart';
import 'globals.dart';
import 'package:draw/draw.dart';
import 'package:url_launcher/url_launcher.dart';
import 'credential_loader.dart';

class PostsProvider {
  static final PostsProvider _instance = new PostsProvider._internal();
  PostsProvider._internal();

  factory PostsProvider(){
    return _instance;
  }
  
  Client client = Client();
  final _apiKey = 'your_api_key';
  Reddit reddit;

  Future<bool> isLoggedIn() async {
    var r = await getRed();
    return r.readOnly ? false : true;
  }
  Future<void> logInAsGuest() async {
    reddit = await getReadOnlyReddit();
  }
  Future<bool> logIn(String username) async{
    var credentials = await readCredentials(username);
    if(credentials != null){
      reddit = await getRed();
      var cUserDisplayname = "";
      if(!reddit.readOnly){
        var currentUser = await reddit.user.me();
        cUserDisplayname = currentUser.displayName;
      }
      print("cuser:" + cUserDisplayname);
      if(cUserDisplayname.toLowerCase() != username.toLowerCase()){
        //Prevent useless logins
        reddit = await restoreAuth(credentials);
        updateLogInDate(username);
      }
      return true;
    }
    return false;
  }
  Future<bool> logInToLatest() async {
    var latestUser = await getLatestUser();
    if(latestUser != null){
      logIn(latestUser.username);
      return true;
    }else{
      reddit = await getRed();
      return false;
    }
  }
  
  Future<Reddit> restoreAuth(String jsonCredentials) async {
    final configUri = Uri.parse('draw.ini');
    var userAgent = "$appName $appVersion by u/tipezuke";
    return await Reddit.restoreAuthenticatedInstance(
        jsonCredentials,
        userAgent: userAgent,
        configUri: configUri,
        clientSecret: "",
        clientId: "JfjOgtm3pWG22g"
      );
  }
  checkForRefresh() async {
    if(reddit.auth.credentials.isExpired){
      var x = await reddit.auth.credentials.refresh();
      var name = await reddit.user.me();
      reddit = await restoreAuth(x.toJson());
      updateCredentials(name.fullname, x.toJson());
    }
  }

  void registerReddit() async {
    var userAgent = "$appName $appVersion by u/tipezuke";
    final configUri = Uri.parse('draw.ini');
    var redirectUri = Uri.http("localhost:8080", "");

    reddit = await getRed();
    print("CREATED NEW FLOW INSTANCE");
      reddit = Reddit.createInstalledFlowInstance(
        clientId: "JfjOgtm3pWG22g",
        userAgent: userAgent,
        configUri: configUri,
        redirectUri: redirectUri,
      );
    Stream<String> onCode = await _server();
    final auth_url = reddit.auth.url(['*'], userAgent);
    launch(auth_url.toString());
    final String code = await onCode.first;

    await reddit.auth.authorize(code);
    
    var user = await reddit.user.me();

    writeCredentials(user.displayName, reddit.auth.credentials.toJson());
    
  }
  Future<Stream<String>> _server() async {
    final StreamController<String> onCode = new StreamController();
    HttpServer server =
      await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8080);
    server.listen((HttpRequest request) async {
      final String code = request.uri.queryParameters["code"];
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.HTML.mimeType)
        ..write("<html><h1>You can now close this window</h1></html>");
      await request.response.close();
      await server.close(force: true);
      onCode.add(code);
      await onCode.close();
    });
    return onCode.stream;
  }
  Future<RedditUser> getLatestUser() async {
    var list = await getAllUsers();
    if(list == null || list.isEmpty) return null;
    list.sort((user1, user2) => user1.date.compareTo(user2.date));
    print(list.last.username + " IS THE LATEST USER");
    list.forEach((r)=>{
      print(r.username + r.date.toString())
    });
    return list.last;
  }
  Future<Reddit> getRed() async {
    if(reddit == null){
      return getReadOnlyReddit();
    }else{
      return reddit;
    }
  }
  Future<Reddit> getReadOnlyReddit() async {
    return Reddit.createReadOnlyInstance(
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
    var res = await logInToLatest();
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
              var v = await reddit.subreddit(currentSubreddit).hot(params: headers).toList();
              return ItemModel.fromApi(v);
            case "new":
              var v = await reddit.subreddit(currentSubreddit).newest(params: headers).toList();
              return ItemModel.fromApi(v);
            case "rising":
              var v = await reddit.subreddit(currentSubreddit).rising(params: headers).toList();
              return ItemModel.fromApi(v);
        }
    }else{
      var filter = parseTimeFilter(timeFilter);
      switch (typeFilter){
            case "controversial":
              var v = await reddit.subreddit(currentSubreddit).controversial(timeFilter: filter, params: headers).toList();
              return ItemModel.fromApi(v);
            case "top":
              var v = await reddit.subreddit(currentSubreddit).top(timeFilter: filter, params: headers).toList();
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