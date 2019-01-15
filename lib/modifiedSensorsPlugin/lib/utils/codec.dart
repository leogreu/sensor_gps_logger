part of sensors;

class Codec {
  static String encodeSensorSampleRate(SampleRate sampleRate) {
    return sampleRate.toString().split('.').last;
  }
}
