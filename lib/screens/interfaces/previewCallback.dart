abstract class PreviewCallback{
  void preview(String u);
  void previewEnd();
  Future<bool> canPop();
}

abstract class MediaViewerCallback {
  Future<bool> canPopMediaViewer();
}

// Source view of preview. Needed for deciding whether to show every line of selftext
enum PreviewSource{
  Comments,
  PostsList
}