// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyreThemeAdapter extends TypeAdapter<LyreTheme> {
  @override
  final typeId = 1;

  @override
  LyreTheme read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyreTheme(
      name: fields[0] as String,
      borderRadius: fields[9] as int,
      contentElevation: fields[10] as double,
    );
  }

  @override
  void write(BinaryWriter writer, LyreTheme obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.primaryColor)
      ..writeByte(2)
      ..write(obj.accentColor)
      ..writeByte(3)
      ..write(obj.highLightColor)
      ..writeByte(4)
      ..write(obj.primaryTextColor)
      ..writeByte(5)
      ..write(obj.secondaryTextColor)
      ..writeByte(6)
      ..write(obj.pinnedTextColor)
      ..writeByte(7)
      ..write(obj.canvasColor)
      ..writeByte(8)
      ..write(obj.contentBackgroundColor)
      ..writeByte(9)
      ..write(obj.borderRadius)
      ..writeByte(10)
      ..write(obj.contentElevation);
  }
}
