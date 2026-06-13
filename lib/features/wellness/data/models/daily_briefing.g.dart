// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_briefing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyBriefingAdapter extends TypeAdapter<DailyBriefing> {
  @override
  final int typeId = 3;

  @override
  DailyBriefing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyBriefing(
      date: fields[0] as String,
      summary: fields[1] as String,
      insights: (fields[2] as List).cast<String>(),
      recommendations: (fields[3] as List).cast<String>(),
      source: fields[4] as String,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyBriefing obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.summary)
      ..writeByte(2)
      ..write(obj.insights)
      ..writeByte(3)
      ..write(obj.recommendations)
      ..writeByte(4)
      ..write(obj.source)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyBriefingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
