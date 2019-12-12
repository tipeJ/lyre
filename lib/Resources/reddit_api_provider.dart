import 'dart:async';
import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' show Client;
import 'package:lyre/Resources/filter_manager.dart';
import 'dart:convert';
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
  factory PostsProvider(){
    return _instance;
  }

  static final PostsProvider _instance = new PostsProvider._internal();

  PostsProvider._internal();

  Client client = Client();
  Reddit reddit;

  Future<Redditor> getLoggedInUser(){
    if(reddit == null || reddit.readOnly){
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
  }

  Future<Redditor> getRedditor(String fullname) async {
    var r = await getRed();
    return r.redditor(fullname).populate();
  }

  Future<Redditor> logIn(String username) async{
    if (username.isEmpty) { //Read-only
      reddit = await getReadOnlyReddit();
      return null;
    } else {
      var credentials = await readCredentials(username);
      if(credentials != null){
        reddit = await getRed();
        var cUserDisplayname = "";
        if(!reddit.readOnly){
          cUserDisplayname = (await reddit.user.me()).displayName;
        }
        if(cUserDisplayname.toLowerCase() != username.toLowerCase()){
          //Prevent useless logins
          reddit = await restoreAuth(credentials);
          updateLogInDate(username);
        }
        if(reddit.readOnly){
          return null;
        }else{
          return reddit.user.me();
        }
      }
      return null;
    }
  }
  Future<CommentRef> getCRef(String id) async {
    final r = await getRed();
    return CommentRef.withID(r, id);
  }

  Future<Redditor> logInToLatest() async {
    if(reddit != null && !reddit.readOnly){
      return reddit.user.me();
    }
    final latestUser = await getLatestUser();
    if(latestUser != null){
      final user = await logIn(latestUser.username);
      return user;
    }
    return null;
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

  Future<Map<String, Stream<String>>> redditAuthUrl() async {
    final userAgent = "$appName $appVersion by the developer u/tipezuke";
    final configUri = Uri.parse('draw.ini');
    final redirectUri = Uri.http("localhost:8080", "");

    reddit = await getRed();
    reddit = Reddit.createInstalledFlowInstance(
        clientId: "JfjOgtm3pWG22g",
        userAgent: userAgent,
        configUri: configUri,
        redirectUri: redirectUri,
      );
    Stream<String> onCode = await _serverStream();
    return {
      reddit.auth.url(['*'], userAgent, compactLogin: true).toString() : onCode
    };
  }

  Future<String> auth(Stream<String> onCode) async {
    final String code = await onCode.first;

    //Close the no-longer needed server
    await closeAuthServer();

    await reddit.auth.authorize(code);
    
    var user = await reddit.user.me();

    await writeCredentials(user.displayName, reddit.auth.credentials.toJson());

    return user.displayName;
  }

  Future<void> closeAuthServer() {
    return _server.close(force: true);
  }

  //Httpserver used for authenticating the App with a Reddit account
  HttpServer _server;
  
  Future<Stream<String>> _serverStream() async {
    final StreamController<String> onCode = new StreamController();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
    _server.listen((HttpRequest request) async {
      final String code = request.uri.queryParameters["code"];
      request.response
        ..statusCode = 200
        ..headers.set("Content-Type", ContentType.html.mimeType)
        ..write("<html><h1>You can now close this window</h1></html>");
      await request.response.close();
      await _server.close(force: true);
      onCode.add(code);
      await onCode.close();
    });
    return onCode.stream;
  }

  Future<RedditUser> getLatestUser() async {
    var list = await getAllUsers();
    if(list == null || list.isEmpty) return null;
    list.sort((user1, user2) => user1.date.compareTo(user2.date));
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

  Future<Map<dynamic, dynamic>> fetchRedditContent(String query) async {
    final r = await getRed();
    Map<String, String> headers = new Map<String, String>();
      headers["api_type"] = "json";
    
    final x = await client.get(query);

    final jsonResponse = json.decode(x.body);

    final Map<dynamic, dynamic> map = Map();

    if (jsonResponse.length > 1) {
      final o = r.objector.objectify(jsonResponse[0]).values.first.first;
      final o2 = r.objector.objectify(jsonResponse[1]).values.first;
      map[o] = o2;

    }
    return map;    
  }

  ///Fetches User Content from Reddit. Return values may contain either Comments or Submissions
  Future<List<UserContent>> fetchUserContent(TypeFilter typeFilter, bool loadMore, {String timeFilter, String redditor, ContentSource source}) async {
    reddit = await getRed();

    Map<String, String> params = new Map<String, String>();

    if(loadMore)params["after"]="t3_$lastPost";

    params["limit"] = perPage.toString();
    params["raw_json"] = '1';

    if([
      TypeFilter.Hot,
      TypeFilter.New,
      TypeFilter.Rising,
      TypeFilter.Gilded
    ].contains(typeFilter)){
      timeFilter = "";
      //This is to ensure that no unfitting timefilters get bundled with specific-time typefilters.
    }

    List<UserContent> v = [];
    if(timeFilter == ""){
      switch (typeFilter){
        case TypeFilter.New:
          if (source == ContentSource.Subreddit){
            v = await reddit.subreddit(currentSubreddit).newest(params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(redditor).newest(params: params).toList();
          }
          break;
        case TypeFilter.Rising:
          if (source == ContentSource.Subreddit){
            v = await reddit.subreddit(currentSubreddit).rising(params: params).toList();
          }
          break;
        case TypeFilter.Gilded:
          if (source == ContentSource.Subreddit){
            // ! Implement?
          }
          break;
        case TypeFilter.Comments:
          // ! Implement?
          break;
        default: //Default to hot.
          if (source == ContentSource.Subreddit){
            v = await reddit.subreddit(currentSubreddit).hot(params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(redditor).hot(params: params).toList();
          }
          break;
      }
    }else{
      var filter = parseTimeFilter(timeFilter);
      switch (typeFilter){
        case TypeFilter.Controversial:
          if (source == ContentSource.Subreddit){
              v = await reddit.subreddit(currentSubreddit).controversial(timeFilter: filter, params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(redditor).controversial(timeFilter: filter, params: params).toList();
          }
          break;
        default: //Default to top
          if (source == ContentSource.Subreddit){
              v = await reddit.subreddit(currentSubreddit).top(timeFilter: filter, params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(redditor).top(timeFilter: filter, params: params).toList();
          }
          break;
      }
    }
    //Filter nothing if the contentsource is Self
    if (source != ContentSource.Self) {
      await FilterManager().openFiltersDB();
      //Remove submissions using FilterManager
      v.removeWhere((u) => u is Submission && FilterManager().isFiltered(source: source, submission: u, target: (source == ContentSource.Redditor ? redditor.toLowerCase() : currentSubreddit.toLowerCase())));
    }
    return v;
  }

  Future<CommentM> fetchCommentsList() async {
    var r = await getRed();
    var s = await r.submission(id: currentPostId).populate();
    return CommentM.fromJson(s.comments.comments);
  }

  Future<Subreddit> getSubreddit(String displayName) async {
    if (displayName == 'all') return null;
    try {
      return await reddit.subreddit(displayName).populate();
    } catch (e) {
      return null;
    }
  }

  Future<List<StyleSheetImage>> getStyleSheetImages(Subreddit subreddit) async {
    final styleSheet = await subreddit.stylesheet.call();
    return styleSheet.images;
  }

  Future<WikiPage> getWikiPage(String args, String displayName) async {
    if (displayName == 'all') return null;
    //return null;
    try {    
      final r = await getRed();
      final subreddit = await r.subreddit(currentSubreddit).populate(); //Populate the subreddit
      final page = await subreddit.wiki[args].populate();
      return page;
    } catch (e) {
      return null;
    } //Fetch wiki page content for the sidebar
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
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await client.get("${SUBREDDITS_BASE_URL}search.json?q=r/${query}&include_over_18=on", headers: headers);
    if(response.statusCode == 200){
      return SubredditM.fromJson(json.decode(response.body)["data"]["children"]);
    } else {
      throw Exception('Failed to load subreddits');
    }
  }

  // * Search

  Future<List<UserContent>> search({String query, String subReddit, String timeFilter}) {
    if (notNull(subReddit)) {
      return reddit.subreddit(subReddit).search(query, timeFilter: parseTimeFilter(timeFilter)).toList();
    } else {
      return reddit.subreddit('all').search(query, timeFilter: parseTimeFilter(timeFilter)).toList();
    }
  }

  ///Function which will return a list of Draw objects, either Subreddits or Redditors
  Future<List<dynamic>> searchCommunities(String query, {bool loadMore = false, String lastId = ""}) async {
    final Map<String, String> params = <String, String>{
      'raw_json' : '1',
      'q' : query,
      'sort' : 'relevance',
      'syntax' : 'lucene',
      'type' : 'user,sr',
    };
    params["User-Agent"] = "$appName $appVersion";
    if (loadMore) params['after'] = lastId;
    dynamic x2 = await reddit.get('r/all/search/', params: params, objectify: false);
    List<dynamic> values = [];
    x2['data']['children'].forEach((o) {
      if(o is Subreddit || o is Redditor) {
        values.add(o);
      } else {
        // Turns the hashMap into a reddit object. For some reason objector doesn't objectify the user maps. For this we'll use the parse function 
        var object = reddit.objector.objectify(o);
        if (!(object is Subreddit)) object = Redditor.parse(reddit, object);
        values.add(object);
      }
    });
    return values;
  }
  ///Function which will return a list of UserContent from PushShift search
  Future<List<dynamic>> searchPushShiftComments(CommentSearchParameters parameters, {bool loadMore = false}) async {
    final Map<String, dynamic> params = <String, dynamic>{
      'raw_json' : '1',
      'q' : parameters.query,
      'size' : parameters.size?.toString(),
      'sort' : _parsePushShiftSort(parameters.sort),
      'sort_type' : _parsePushShiftSortType(parameters.sortType),
      'author' : parameters.author,
      'subreddit' : parameters.subreddit
    };
    final Map<String, String> headers = <String, String>{
      'User-Agent' : "$appName $appVersion"
    };
    // ! Can't Process num_comments with a comment search. Will Throw Exception.
    dynamic results = await HttpUtils.getForJson('https://api.pushshift.io/reddit/search/comment/', queryParameters: params, headers: headers);
    List<dynamic> values = [];
    results['data'].forEach((o) {
      var object;
      //Draw refuses to parse a created_utc in int format (Which pushShift returns), so we'll convert it do double.
      o['created_utc'] = o['created_utc'].toDouble();
      object = Comment.parse(reddit, o);
      values.add(object);
    });
    return values;
  }

  // * Profile data fetching:

  Future<List<UserContent>> fetchSelfUserContent(bool loadMore, SelfContentType contentType, {TypeFilter typeFilter, String timeFilter = ""}) async {
    var r = await getRed();
    var self = await r.user.me();
    var filter = parseTimeFilter(timeFilter);
    switch (contentType) {
      case SelfContentType.Comments:
        var comments = self.comments;
        switch (typeFilter) {
          case TypeFilter.Top:
            return comments.top(timeFilter: filter).toList();
          case TypeFilter.Controversial:
            return comments.controversial(timeFilter: filter).toList();
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
            return submitted.top(timeFilter: filter).toList();
          case TypeFilter.Controversial:
            return submitted.controversial(timeFilter: filter).toList();
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

/// Class for sorting [Comment] and [Submission] objects searched via PushShift Search
enum PushShiftSort {
  Asending,
  Descending
}
/// Parse the sort type for [PushShiftSort] object. Used for HTTP requests from API, which required a String object.
String _parsePushShiftSort(PushShiftSort sort) => sort != null ? sort == PushShiftSort.Asending ? "asc" : "desc" : null;

/// Type to be used in [PushShiftSort] for Specific sort types
enum PushShiftSortType {
  Score,
  Num_Comments,
  Created_UTC
}
/// Parse the sort type for [PushShiftSortType] object. Used for HTTP requests from API, which required a String object.
String _parsePushShiftSortType(PushShiftSortType sort) => sort != null ? sort.toString().toLowerCase().split('.').last : null;

/// Class for sorting [Comment] and [Submission] objects searched via PushShift Search
enum PushShiftFrequency {
  Second,
  Minute,
  Hour,
  Day
}

abstract class PushShiftSearchParameters {
  String query;
}

class CommentSearchParameters extends PushShiftSearchParameters{

  @override
  ///Search term.
  final String query;

  ///Get specific comments via their ids
  String ids;

  ///Number of results to return	
  int size;

  ///One return specific fields (comma delimited)	
  String fields;

  ///Sort results in a specific order	
  PushShiftSort sort;

  ///Sort by a specific attribute	
  PushShiftSortType sortType;

  ///Return aggregation summary	
  List<String> aggs;

  ///Restrict to a specific author	
  String author;

  ///Restrict to a specific subreddit
  String subreddit;

  ///Return results after this date	
  String after;

  ///Return results before this date	
  String before;

  ///Used with the aggs parameter when set to created_utc	
  PushShiftFrequency frequency;

  ///display metadata about the query
  bool includeMetadata;

  /// Class for retrieving [Comment] objects via PushShift Search API
  CommentSearchParameters({
    @required this.query,
    this.ids,
    this.size,
    this.fields,
    this.sort,
    this.sortType,
    this.aggs,
    this.author,
    this.subreddit,
    this.after,
    this.before,
    this.frequency,
    this.includeMetadata
  }) : assert(query != null);
}