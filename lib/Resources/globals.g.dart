// GENERATED CODE - DO NOT MODIFY BY HAND

part of lyre.globals;

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostsViewAdapter extends TypeAdapter<PostView> {
  @override
  final typeId = 0;

  @override
  PostView read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PostView.ImagePreview;
      case 1:
        return PostView.IntendedPreview;
      case 2:
        return PostView.Compact;
      case 3:
        return PostView.NoPreview;
      default:
        return null;
    }
  }

  @override
  void write(BinaryWriter writer, PostView obj) {
    switch (obj) {
      case PostView.ImagePreview:
        writer.writeByte(0);
        break;
      case PostView.IntendedPreview:
        writer.writeByte(1);
        break;
      case PostView.Compact:
        writer.writeByte(2);
        break;
      case PostView.NoPreview:
        writer.writeByte(3);
        break;
    }
  }
}
