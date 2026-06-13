// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_check_in.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MoodCheckInAdapter extends TypeAdapter<MoodCheckIn> {
  @override
  final int typeId = 2;

  @override
  MoodCheckIn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodCheckIn(
      date: fields[0] as String,
      moodScore: fields[1] as int,
      energyScore: fields[2] as int,
      stressScore: fields[3] as int,
      note: fields[4] as String,
      createdAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, MoodCheckIn obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.moodScore)
      ..writeByte(2)
      ..write(obj.energyScore)
      ..writeByte(3)
      ..write(obj.stressScore)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodCheckInAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
