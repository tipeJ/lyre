final supportedFormats = [
  "jpg",
  "png",
  "gif",
  "webp",
  "bmp"
];
String getYoutubeThumbnailFromId(String id){
  return "https://img.youtube.com/vi/$id/hqdefault.jpg";
}