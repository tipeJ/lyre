import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';

const FILTER_SUBREDDITS_BOX = "subredditsfilters";
const FILTER_USERS_BOX = "usersfilters";
const FILTER_DOMAINS_BOX = "domainsfilters";

class FilterManager {
  static final FilterManager _instance = new FilterManager._internal();
  FilterManager._internal();

  factory FilterManager(){
    return _instance;
  }

  // ? Migrate to something else? Moor, for example. Speed is the key here tho

  Box _filteredSubredditsBox;
  Box _filteredUsersBox;

  openFiltersDB() async {
    _filteredSubredditsBox = await Hive.openBox(FILTER_SUBREDDITS_BOX);
    _filteredUsersBox = await Hive.openBox(FILTER_USERS_BOX);
  }
  
  closeFiltersDB() async {
    _filteredSubredditsBox?.close();
    _filteredUsersBox?.close();
  }

  ///Checks whether given [Submission] should be filtered
  bool isFiltered(ContentSource source, Submission submission, [String target]) {
    bool equalsTarget;
    /*
    if (source == ContentSource.Subreddit) {
      equalsTarget = submission.subreddit.displayName.toLowerCase() == target;
    } else {
      equalsTarget = submission.author.toLowerCase() == target;
    }

    //Return false if target is the same as the possibly filtered content (Filters do not go into effect if, for example, user visits a filtered subreddit)
    if (equalsTarget) return false;
    */
    if (_filteredSubredditsBox.values.contains(submission.subreddit.displayName.toLowerCase()) || _filteredUsersBox.values.contains(submission.author.toLowerCase())) return true;
    return false;
  }
}