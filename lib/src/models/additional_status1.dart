import '../../flutter_ble_c2pm.dart';

enum AdditionalStatus1ByteFieldIndex {
  ELAPSED_TIME_LO,
  ELAPSED_TIME_MID,
  ELAPSED_TIME_HI,
  SPEED_LO,
  SPEED_HI,
  STROKE_RATE,
  HEART_RATE,
  CURRENT_PACE_LO,
  CURRENT_PACE_HI,
  AVERAGE_PACE_LO,
  AVERAGE_PACE_HI,
  REST_DISTANCE_LO,
  REST_DISTANCE_HI,
  REST_TIME_LO,
  REST_TIME_MID,
  REST_TIME_HI,
  AVERAGE_POWER_LO,
  AVERAGE_POWER_HI,
  ERG_MACHINE_TYPE
}

class AdditionalStatus1 extends PmData<AdditionalStatus1> {
  static final int uuid = 'ce060033-43e5-11e4-916c-0800200c9a66'.hashCode;

  double elapsedTime = 0.0;
  double speed = 0.0;
  int strokeRate = 0;
  int heartRate = 0;
  double currentPace = 0.0;
  double averagePace = 0.0;
  int restDistance = 0;
  double restTime = 0.0;
  int averagePower = 0;
  int ergMachineType = 0;

  @override
  Map<String, dynamic> toJson() {
    return {
      'elapsedTime': elapsedTime,
      'speed': speed,
      'strokeRate': strokeRate,
      'heartRate': heartRate,
      'currentPace': currentPace,
      'averagePace': averagePace,
      'restDistance': restDistance,
      'restTime': restDistance,
      'averagePower': averagePower,
      'ergMachineType': ergMachineType
    };
  }

  @override
  AdditionalStatus1 from(List<int> intList) {
    // @formatter:off
    elapsedTime = DataConvUtils.getUint24(intList, AdditionalStatus1ByteFieldIndex.ELAPSED_TIME_LO.index) / 100;
    speed = DataConvUtils.getUint16(intList, AdditionalStatus1ByteFieldIndex.SPEED_LO.index) / 1000;
    strokeRate = DataConvUtils.getUint8(intList, AdditionalStatus1ByteFieldIndex.STROKE_RATE.index);
    heartRate = DataConvUtils.getUint8(intList, AdditionalStatus1ByteFieldIndex.HEART_RATE.index);
    currentPace = DataConvUtils.getUint16(intList, AdditionalStatus1ByteFieldIndex.CURRENT_PACE_LO.index) / 100;
    averagePace = DataConvUtils.getUint16(intList, AdditionalStatus1ByteFieldIndex.AVERAGE_PACE_LO.index) / 100;
    restDistance = DataConvUtils.getUint16(intList, AdditionalStatus1ByteFieldIndex.REST_DISTANCE_LO.index);
    restTime = DataConvUtils.getUint24(intList, AdditionalStatus1ByteFieldIndex.REST_TIME_LO.index) / 100;
    averagePower = DataConvUtils.getUint16(intList, AdditionalStatus1ByteFieldIndex.AVERAGE_POWER_LO.index);
    ergMachineType = DataConvUtils.getUint8(intList, AdditionalStatus1ByteFieldIndex.ERG_MACHINE_TYPE.index);
    // @formatter:on
    return this;
  }
}
