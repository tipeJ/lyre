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
  static final FilterManager _instance = FilterManager._internal();
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

  /// Assumes that every box in in the same state
  bool get isOpen => _filteredSubredditsBox.isOpen;
  
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
    bool equalsTarget = false;

    if (source == ContentSource.Subreddit) {
      equalsTarget = submission.subreddit.displayName.toLowerCase() == target.toLowerCase();
    } else if (source == ContentSource.Redditor) {
      equalsTarget = submission.author.toLowerCase() == target.toLowerCase();    
    } else if (source == ContentSource.Domain) {  
      equalsTarget = submission.url.authority == target.toLowerCase();
    }

    //Return false if target is the same as the possibly filtered content (Filters do not go into effect if, for example, user visits a filtered subreddit)
    if (equalsTarget || source == ContentSource.Self) return false;

    final subreddit = submission.subreddit.displayName.toLowerCase();
    final author = submission.author.toLowerCase();
    final domain = submission.url.host.replaceAll("www.", "").toLowerCase();

    if (_filteredSubredditsBox.values.contains(subreddit) || _filteredUsersBox.values.contains(author) || _filteredDomainsBox.values.contains(domain)) return true;
    
    return false;
  }
}