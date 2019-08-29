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

enum ContentSource{
  Subreddit,
  Redditor,
  Self
}

enum SelfContentType{
  Comments,
  Submitted,
  Upvoted,
  Saved,
  Hidden,
  Watching
}

enum TypeFilter{
  Best,
  Hot,
  New,
  Rising,
  Top,
  Controversial,
  Gilded,
  Comments
}

class PostsProvider {
  static final PostsProvider _instance = new PostsProvider._internal();
  PostsProvider._internal();

  factory PostsProvider(){
    return _instance;
  }
  
  Client client = Client();
  final _apiKey = 'your_api_key';
  Reddit reddit;

  Future<Redditor> getLoggedInUser(){
    if(reddit == null){
      return null;
    }
    return reddit.user.me();
  }
  bool isLoggedIn() {
    if(reddit == null){
      return false;
    }
    return reddit.readOnly ? false : true;
  }
  logInAsGuest() async {
    reddit = await getReadOnlyReddit();
    currentUser.value = "Guest";
  }
  Future<Redditor> getRedditor(String fullname) async {
    var r = await getRed();
    return r.redditor(fullname).populate();
  }
  Future<bool> logIn(String username) async{
    var credentials = await readCredentials(username);
    if(credentials != null){
      print("CREDENTIALS WEREN'T NULL");
      reddit = await getRed();
      var cUserDisplayname = "";
      if(!reddit.readOnly){
        reddit.user.me().then((redditor){
          cUserDisplayname = redditor.displayName;
        });
      }
      print("cuser:" + cUserDisplayname);
      if(cUserDisplayname.toLowerCase() != username.toLowerCase()){
        //Prevent useless logins
        reddit = await restoreAuth(credentials);
        updateLogInDate(username);
      }
      if(reddit.readOnly){
        currentUser.value = "Guest";
      }else{
        reddit.user.me().then((me){
          currentUser.value = me.displayName;
        });
      }
      return true;
    }
    print("CREDENTIALS WERE NULL");
    return false;
  }
  Future<bool> logInToLatest() async {
    if(reddit != null && !reddit.readOnly){
      return true;
    }
    //TODO: FIX (THIS IS NOT GOOD)
    if(currentUser.value == "Guest"){
      return true;
    }
    getLatestUser().then((latestUser){
      if(latestUser != null){
        logIn(latestUser.username).then((_){
          return true;
      });
    }else{
      getRed().then((r){
        reddit = r;
        return false;
      });
    }
    });
    return false;
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
    var userAgent = "$appName $appVersion by the developer u/tipezuke";
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
    final auth_url = reddit.auth.url(['*'], userAgent, compactLogin: true);

    print("TOS: " + auth_url.toString());
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
    
    var b2 = CommentM.fromJson2(response);
    return b2;
  }

  Future<ItemModel> fetchUserContent(String typeFilter, String timeFilter, bool loadMore, {String redditor, ContentSource source}) async {
    var res = await logInToLatest();
    reddit = await getRed();

    Map<String, String> headers = new Map<String, String>();

    if(loadMore)headers["after"]="t3_$lastPost";

    headers["limit"] = perPage.toString();
    if(typeFilter == "hot" || typeFilter == "new" || typeFilter == "rising"){
      timeFilter = "";
      //This is to ensure that no unfitting timefilters get bundled with specific-time typefilters.
    }
    List<UserContent> v = [];
    if(timeFilter == ""){
      switch (typeFilter){
            case "hot":
              if(source == ContentSource.Subreddit){
                v = await reddit.subreddit(currentSubreddit).hot(params: headers).toList();
              }else if(source == ContentSource.Redditor){
                v = await reddit.redditor(redditor).hot(params: headers).toList();
              }
              break;
            case "new":
              if(source == ContentSource.Subreddit){
                v = await reddit.subreddit(currentSubreddit).newest(params: headers).toList();
              }else if(source == ContentSource.Redditor){
                v = await reddit.redditor(redditor).newest(params: headers).toList();
              }
              break;
            case "rising":
              if(source == ContentSource.Subreddit){
                v = await reddit.subreddit(currentSubreddit).rising(params: headers).toList();
              }
              break;
        }
    }else{
      var filter = parseTimeFilter(timeFilter);
      switch (typeFilter){
            case "controversial":
              if(source == ContentSource.Subreddit){
                  v = await reddit.subreddit(currentSubreddit).controversial(timeFilter: filter, params: headers).toList();
              }else if(source == ContentSource.Redditor){
                v = await reddit.redditor(redditor).controversial(timeFilter: filter, params: headers).toList();
              }
              break;
            case "top":
              if(source == ContentSource.Subreddit){
                  v = await reddit.subreddit(currentSubreddit).top(timeFilter: filter, params: headers).toList();
              }else if(source == ContentSource.Redditor){
                v = await reddit.redditor(redditor).top(timeFilter: filter, params: headers).toList();
              }
              break;
        }
    }
    return ItemModel.fromApi(v);
  }
  Future<CommentM> fetchCommentsList() async {
    Map<String, String> headers = new Map<String, String>();
    headers["before"] = "0";

    var r = await getRed();
    var s = await r.submission(id: currentPostId).populate();
    return CommentM.fromJson(s.comments.comments);
  }
  List<dynamic> getData(List<dynamic> data){
    List<dynamic> result = List();
    for(int i = 0; i < data.length; i++){
      var x = data[i];
      result.add(x);
      if(x is Comment && x.replies != null && x.replies.comments.isNotEmpty){
        result.addAll(getData(x.replies.comments));
      }
    }
    return result;
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

  //* Profile data fetching:

  Future<List<UserContent>> getSelfUserContent(SelfContentType contentType, [TypeFilter typeFilter, String time_filter = ""]) async {
    var r = await getRed();
    var self = await r.user.me();
    var timeFilter = parseTimeFilter(time_filter);
    switch (contentType) {
      case SelfContentType.Comments:
        var comments = self.comments;
        switch (typeFilter) {
          case TypeFilter.Top:
            return comments.top(timeFilter: timeFilter).toList();
          case TypeFilter.Controversial:
            return comments.controversial(timeFilter: timeFilter).toList();
          case TypeFilter.New:
            return comments.newest().toList();
          default:
            //Default: Return hot
            return comments.hot().toList();
        }
        break;
      case SelfContentType.Hidden:
        var hidden = self.hidden();
        return hidden.toList();
      case SelfContentType.Submitted:
        var submitted = self.submissions;
        switch (typeFilter) {
          case TypeFilter.Top:
            return submitted.top(timeFilter: timeFilter).toList();
          case TypeFilter.Controversial:
            return submitted.controversial(timeFilter: timeFilter).toList();
          case TypeFilter.New:
            return submitted.newest().toList();
          default:
            //Default: Return hot
            return submitted.hot().toList();
        }
        break;
      case SelfContentType.Upvoted:
        var upvoted = self.upvoted();
        return upvoted.toList();
      case SelfContentType.Saved:
        return self.saved().toList();
      case SelfContentType.Watching:
        // ! API Doesn't support
      default:
        return null; // Shouldn't happen
    }
  }

  //* Utilities: 
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