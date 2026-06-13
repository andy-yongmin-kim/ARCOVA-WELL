// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_health_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyHealthDataAdapter extends TypeAdapter<DailyHealthData> {
  @override
  final int typeId = 1;

  @override
  DailyHealthData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyHealthData(
      date: fields[0] as String,
      sleepDurationMinutes: fields[1] as int,
      steps: fields[2] as int,
      activeMinutes: fields[3] as int,
      restingHeartRate: fields[4] as int,
      updatedAt: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyHealthData obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.sleepDurationMinutes)
      ..writeByte(2)
      ..write(obj.steps)
      ..writeByte(3)
      ..write(obj.activeMinutes)
      ..writeByte(4)
      ..write(obj.restingHeartRate)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyHealthDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
