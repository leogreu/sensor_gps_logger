part of sensors;

class Codec {
  static String encodeSensorEventInterval(SensorSampleRate sensorSampleRate) {
    return sensorSampleRate.toString().split('.').last;
  }
}
