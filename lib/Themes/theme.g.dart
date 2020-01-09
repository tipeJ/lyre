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
      primaryColor: fields[1] as Color,
      accentColor: fields[2] as Color,
      highLightColor: fields[3] as Color,
      primaryTextColor: fields[4] as Color,
      secondaryTextColor: fields[5] as Color,
      pinnedTextColor: fields[6] as Color,
      canvasColor: fields[7] as Color,
      contentBackgroundColor: fields[8] as Color,
      borderRadius: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LyreTheme obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.borderRadius);
  }
}
