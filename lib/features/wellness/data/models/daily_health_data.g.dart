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
      weight: fields[6] as double?,
      bodyMassIndex: fields[7] as double?,
      bodyFatPercentage: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyHealthData obj) {
    writer
      ..writeByte(9)
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
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.weight)
      ..writeByte(7)
      ..write(obj.bodyMassIndex)
      ..writeByte(8)
      ..write(obj.bodyFatPercentage);
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
