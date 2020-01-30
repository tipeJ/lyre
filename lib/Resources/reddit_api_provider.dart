import 'dart:async';
import 'dart:io';
import 'package:basic_utils/basic_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';
import 'package:lyre/Models/models.dart' as rModel;
import 'package:lyre/Resources/PreferenceValues.dart';
import 'package:lyre/Resources/filter_manager.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'globals.dart';
import 'package:draw/draw.dart';
import 'credential_loader.dart';

/// Source for listing items (in posts_list)
enum ContentSource{
  Subreddit,
  Frontpage,
  Redditor,
  Domain,
  Self
}

/// Source for self content types
enum SelfContentType{
  Comments,
  Submitted,
  Upvoted,
  Saved,
  Hidden,
  Watching
}
/// Posts-List Filters
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

  Future<Redditor> getRedditor(String fullname) async {
    var r = await getRed();
    return r.redditor(fullname).populate();
  }

  Future<bool> logOut(String username, bool deleteSettings) async {
    final logOutResult = await deleteCredentials(username);
    if (deleteSettings) {
      final box = await Hive.openBox(BOX_SETTINGS_PREFIX + username.toLowerCase());
      await box.deleteFromDisk();
    }
    return logOutResult;
  }

  Future<Redditor> logIn(String username) async {
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
    return Reddit.restoreAuthenticatedInstance(
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

  Future<rModel.RedditUser> getLatestUser() async {
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
    final uuid = Uuid();
    final configUri = Uri.parse('draw.ini');
    final deviceId = uuid.v5(Uuid.NAMESPACE_OID, 'lyre').substring(0, 26);
    return Reddit.createUntrustedReadOnlyInstance(
      userAgent: "$appName $appVersion by u/tipezuke",
      clientId: "JfjOgtm3pWG22g",
      deviceId: deviceId,
      configUri: configUri
    );
  }

  Future<Map<dynamic, dynamic>> fetchRedditContent(String query) async {
    final r = await getRed();
    Map<String, String> headers = Map<String, String>();
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

  ///Fetches User Content from Reddit. Return values may contain either [Comment] or [Submissions]
  Future<List<UserContent>> fetchUserContent(TypeFilter typeFilter, String contentTarget, {String timeFilter, ContentSource source, String after}) async {
    reddit = await getRed();

    Map<String, String> params = new Map<String, String>();

    if(after != null)params["after"]= after;

    params["limit"] = perPage.toString();
    params["raw_json"] = '1';

    if ([
      TypeFilter.Hot,
      TypeFilter.New,
      TypeFilter.Rising,
      TypeFilter.Gilded
    ].contains(typeFilter)){
      timeFilter = "";
      //This is to ensure that no unfitting timefilters get bundled with specific-time typefilters.
    }
    // Trim is needed because some String (especially those loaded from files) are not suitable for fetching data from the API without trimming.
    final target = contentTarget != null ? contentTarget.trim() : '';

    List<UserContent> v = [];
    if(timeFilter == ""){
      switch (typeFilter){
        case TypeFilter.New:
          if (source == ContentSource.Subreddit){
            v = await reddit.subreddit(target).newest(params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(target).newest(params: params).toList();
          } else if (source == ContentSource.Frontpage) {
            v = await reddit.front.newest(params: params).toList();
          }
          break;
        case TypeFilter.Rising:
          if (source == ContentSource.Subreddit){
            v = await reddit.subreddit(target).rising(params: params).toList();
          } else if (source == ContentSource.Frontpage) {
            v = await reddit.front.rising(params: params).toList();
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
            v = await reddit.subreddit(target).hot(params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(target).hot(params: params).toList();
          } else if (source == ContentSource.Frontpage) {
            v = await reddit.front.hot(params: params).toList();
          }
          break;
      }
    } else {
      final filter = parseTimeFilter(timeFilter);
      switch (typeFilter){
        case TypeFilter.Controversial:
          if (source == ContentSource.Subreddit){
            v = await reddit.subreddit(target).controversial(timeFilter: filter, params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(target).controversial(timeFilter: filter, params: params).toList();
          } else if (source == ContentSource.Frontpage) {
            v = await reddit.front.controversial(timeFilter: filter, params: params).toList();
          }
          break;
        default: //Default to top
          if (source == ContentSource.Subreddit){
              v = await reddit.subreddit(target).top(timeFilter: filter, params: params).toList();
          } else if(source == ContentSource.Redditor){
            v = await reddit.redditor(target).top(timeFilter: filter, params: params).toList();
          } else if (source == ContentSource.Frontpage) {
            v = await reddit.front.top(timeFilter: filter, params: params).toList();
          }
          break;
      }
    }
    //Filter nothing if the contentsource is Self
    if (source != ContentSource.Self) {
      await FilterManager().openFiltersDB();
      //Remove submissions using FilterManager
      v.removeWhere((u) => u is Submission && FilterManager().isFiltered(source: source, submission: u, target: target));
    }
    return v;
  }

  // * Profile data fetching:

  Future<List<UserContent>> fetchSelfUserContent(SelfContentType contentType, {TypeFilter typeFilter, String timeFilter = "", String after}) async {
    Map<String, String> params = new Map<String, String>();

    if (after != null) params["after"]= after;

    params["limit"] = perPage.toString();
    params["raw_json"] = '1';
    var r = await getRed();

    var self = await r.user.me();
    var filter = parseTimeFilter(timeFilter);
    Stream<UserContent> userContent;
    switch (contentType) {
      case SelfContentType.Comments:
        final comments = self.comments;
        switch (typeFilter) {
          case TypeFilter.Top:
            userContent = comments.top(timeFilter: filter, params: params);
            break;
          case TypeFilter.Controversial:
            userContent = comments.controversial(timeFilter: filter, params: params);
            break;
          case TypeFilter.New:
            userContent = comments.newest(params: params);
            break;
          default:
            // Return Hot by default
            userContent = comments.hot(params: params);
        }
        break;
      case SelfContentType.Hidden:
        var hidden = self.hidden(params: params);
        userContent = hidden;
        break;
      case SelfContentType.Submitted:
        final submitted = self.submissions;
        switch (typeFilter) {
          case TypeFilter.Top:
            userContent = submitted.top(timeFilter: filter, params: params);
            break;
          case TypeFilter.Controversial:
            userContent = submitted.controversial(timeFilter: filter, params: params);
            break;
          case TypeFilter.New:
            userContent = submitted.newest(params: params);
            break;
          default:
            //Default: Return hot
            userContent = submitted.hot(params: params);
        }
        break;
      case SelfContentType.Upvoted:
        userContent = self.upvoted(params: params);
        break;
      case SelfContentType.Saved:
        userContent = self.saved(params: params);
        break;
      case SelfContentType.Watching:
        // ! API Doesn't support
      default:
        return null; // Shouldn't happen
    }
    return userContent.toList();
  }

  // * Subreddit infornation 

  /// Returns a [Subreddit] with a given displayName. Will return null if a subreddit 
  /// is not found with the given displayName (r/all, r/popular, multireddits, etc.)
  Future<Subreddit> getSubreddit(String displayName) async {
    if (displayName == 'all' || displayName == "popular") return null;
    try {
      return await reddit.subreddit(displayName).populate();
    } catch (e) {
      return null;
    }
  }

  Future<List<StyleSheetImage>> getStyleSheetImages(Subreddit subreddit) async {
    try {    
      final styleSheet = await subreddit.stylesheet.call();
      return styleSheet.images;
    } catch (e) {
      return null;
    } //Fetch wiki page content for the sidebar
  }

  Future<dynamic> getWikiPage(String args, String subreddit) async {
    try {
      final page = await reddit.subreddit(subreddit).wiki[args].populate();
      return page;
    } catch (e) {
      return e.message;
    } //Fetch wiki page content for the sidebar
  }

  /// Get a List of rules in the given Subreddit
  Future<dynamic> getSubredditRules(String subreddit) async {
    try {    
      final rules = await reddit.subreddit(subreddit).rules();
      return rules;
    } catch (e) {
      return e.message;
    } //Fetch rules for a given subreddit
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

  Future<rModel.SubredditM> fetchSubReddits(String query) async {
    query.replaceAll(" ", "+");
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await client.get("${SUBREDDITS_BASE_URL}search.json?q=r/$query&include_over_18=on", headers: headers);
    if(response.statusCode == 200){
      return rModel.SubredditM.fromJson(json.decode(response.body)["data"]["children"]);
    } else {
      throw Exception('Failed to load subreddits');
    }
  }

  Future<Map<String, dynamic>> getTrendingSubreddits() async {
    final response = await client.get('https://www.reddit.com/api/trending_subreddits.json');
    return json.decode(response.body);
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

  // * Utilities: 
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

  Future<Response> httpget(String request, [Map<String, dynamic> headers]) async {
    return client.get(request, headers: headers);
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