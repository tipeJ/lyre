abstract class PreviewCallback{
  void preview(String u);
  void view(String u);
  void previewEnd();
}

// Source view of preview. Needed for deciding whether to show every line of selftext
enum PreviewSource{
  Comments,
  PostsList
}