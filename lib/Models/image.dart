///Class for storing info of network images, especially those belonging to albums. Normal direct links do not need these, as the don't retrieve thumbnails
class LyreImage {
  ///The Main image Url
  final String url;
  ///The Image Description (optional, for services that offer this feature, such as Imgur)
  final String description;
  ///The Url for low-res thumbnail, to be used in gallery views.
  final String thumbnailUrl;

  const LyreImage({this.url, this.description, this.thumbnailUrl});
}