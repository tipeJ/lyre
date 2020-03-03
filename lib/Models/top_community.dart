import 'package:lyre/Resources/resources.dart';

class TopCommunity {
  final String name;
  final String thumbnailUrl;
  final bool isNsfw;

  const TopCommunity({
    this.name,
    this.thumbnailUrl,
    this.isNsfw
  });

  factory TopCommunity.fromJson(dynamic json) => TopCommunity(
    name: json['name'] ?? "Unknown Subreddit",
    thumbnailUrl: json['styles']['icon'] != null ? json['styles']['icon'] :
      json['styles']['legacyIcon'] != null
        ? json['styles']['legacyIcon']["url"]
        : REDDIT_ICON_DEFAULT,
    isNsfw: json["isNSFW"] ?? false,
  );
}