import 'package:draw/draw.dart';
import 'package:hive/hive.dart';
import 'package:lyre/Resources/globals.dart';
import 'package:lyre/Resources/reddit_api_provider.dart';

const FILTER_SUBREDDITS_BOX = "subredditsfilters";
const FILTER_USERS_BOX = "usersfilters";
const FILTER_DOMAINS_BOX = "domainsfilters";

enum FilterType {
  Redditor,
  Subreddit,
  Domain
}

class FilterManager {
  static final FilterManager _instance = new FilterManager._internal();
  FilterManager._internal();

  factory FilterManager(){
    return _instance;
  }

  // ? Migrate to something else? Moor, for example. Speed is the key here tho

  Box _filteredSubredditsBox;
  Box _filteredUsersBox;
  Box _filteredDomainsBox;

  openFiltersDB() async {
    _filteredSubredditsBox = await Hive.openBox(FILTER_SUBREDDITS_BOX);
    _filteredUsersBox = await Hive.openBox(FILTER_USERS_BOX);
    _filteredDomainsBox = await Hive.openBox(FILTER_DOMAINS_BOX);
  }
  
  closeFiltersDB() async {
    _filteredSubredditsBox?.close();
    _filteredUsersBox?.close();
    _filteredDomainsBox?.close();
  }

  ///Filters Target. Can be a Domain, User or a Subreddit
  Future<int> filter(String target, FilterType type) async {
    if (type == FilterType.Subreddit) {
      if (!notNull(_filteredSubredditsBox) && !_filteredSubredditsBox.isOpen) _filteredSubredditsBox = await Hive.openBox(FILTER_SUBREDDITS_BOX);
      return _filteredSubredditsBox.add(target.toLowerCase());
    } else if (type == FilterType.Redditor) {
      if (!notNull(_filteredUsersBox) && !_filteredUsersBox.isOpen) _filteredUsersBox = await Hive.openBox(FILTER_USERS_BOX);
      return _filteredUsersBox.add(target.toLowerCase());
    } else {
      if (!notNull(_filteredDomainsBox) && !_filteredDomainsBox.isOpen) _filteredDomainsBox = await Hive.openBox(FILTER_DOMAINS_BOX);
      return _filteredDomainsBox.add(target.toLowerCase());
    }
  }

  ///Checks whether a given [Submission] should be filtered
  bool isFiltered({ContentSource source, Submission submission, String target}) {
    bool equalsTarget;
    if (source == ContentSource.Subreddit) {
      equalsTarget = submission.subreddit.displayName.toLowerCase() == target;
    } else {
      equalsTarget = submission.author.toLowerCase() == target;
    }

    //Return false if target is the same as the possibly filtered content (Filters do not go into effect if, for example, user visits a filtered subreddit)
    if (equalsTarget) return false;
    if (_filteredSubredditsBox.values.contains(submission.subreddit.displayName.toLowerCase()) || _filteredUsersBox.values.contains(submission.author.toLowerCase()) || _filteredDomainsBox.values.contains(submission.url.authority)) return true;
    return false;
  }
}