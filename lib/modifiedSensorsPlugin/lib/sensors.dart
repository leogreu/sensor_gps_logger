import 'dart:async';
import 'package:flutter/services.dart';

const EventChannel _accelerometerEventChannel =
    EventChannel('plugins.flutter.io/sensors/accelerometer');

const EventChannel _userAccelerometerEventChannel =
    EventChannel('plugins.flutter.io/sensors/user_accel');

const EventChannel _gyroscopeEventChannel =
    EventChannel('plugins.flutter.io/sensors/gyroscope');

class AccelerometerEvent {
  /// Acceleration force along the x axis (including gravity) measured in m/s^2.
  final double x;

  /// Acceleration force along the y axis (including gravity) measured in m/s^2.
  final double y;

  /// Acceleration force along the z axis (including gravity) measured in m/s^2.
  final double z;

  AccelerometerEvent(this.x, this.y, this.z);

  @override
  String toString() => '[AccelerometerEvent (x: $x, y: $y, z: $z)]';
}

class GyroscopeEvent {
  /// Rate of rotation around the x axis measured in rad/s.
  final double x;

  /// Rate of rotation around the y axis measured in rad/s.
  final double y;

  /// Rate of rotation around the z axis measured in rad/s.
  final double z;

  GyroscopeEvent(this.x, this.y, this.z);

  @override
  String toString() => '[GyroscopeEvent (x: $x, y: $y, z: $z)]';
}

class UserAccelerometerEvent {
  /// Acceleration force along the x axis (excluding gravity) measured in m/s^2.
  final double x;

  /// Acceleration force along the y axis (excluding gravity) measured in m/s^2.
  final double y;

  /// Acceleration force along the z axis (excluding gravity) measured in m/s^2.
  final double z;

  UserAccelerometerEvent(this.x, this.y, this.z);

  @override
  String toString() => '[UserAccelerometerEvent (x: $x, y: $y, z: $z)]';
}

enum SensorEventInterval {
  low,
  medium,
  high
}

class Codec {
  static String encodeSensorEventInterval(SensorEventInterval sensorEventInterval) {
    return sensorEventInterval.toString().split('.').last;
  }
}

AccelerometerEvent _listToAccelerometerEvent(List<double> list) {
  return new AccelerometerEvent(list[0], list[1], list[2]);
}

UserAccelerometerEvent _listToUserAccelerometerEvent(List<double> list) {
  return new UserAccelerometerEvent(list[0], list[1], list[2]);
}

GyroscopeEvent _listToGyroscopeEvent(List<double> list) {
  return new GyroscopeEvent(list[0], list[1], list[2]);
}

Stream<AccelerometerEvent> _accelerometerEvents;
Stream<GyroscopeEvent> _gyroscopeEvents;
Stream<UserAccelerometerEvent> _userAccelerometerEvents;

/// A broadcast stream of events from the device accelerometer.
Stream<AccelerometerEvent> getAccelerometerEvents([SensorEventInterval sensorEventInterval = SensorEventInterval.low]) {
  if (_accelerometerEvents == null) {
    _accelerometerEvents = _accelerometerEventChannel
        .receiveBroadcastStream(Codec.encodeSensorEventInterval(sensorEventInterval))
        .map(
            (dynamic event) => _listToAccelerometerEvent(event.cast<double>()));
  }
  return _accelerometerEvents;
}

/// A broadcast stream of events from the device gyroscope.
Stream<GyroscopeEvent> getGyroscopeEvents([SensorEventInterval sensorEventInterval = SensorEventInterval.low]) {
  if (_gyroscopeEvents == null) {
    _gyroscopeEvents = _gyroscopeEventChannel
        .receiveBroadcastStream(Codec.encodeSensorEventInterval(sensorEventInterval))
        .map((dynamic event) => _listToGyroscopeEvent(event.cast<double>()));
  }
  return _gyroscopeEvents;
}

/// Events from the device accelerometer with gravity removed.
Stream<UserAccelerometerEvent> getUserAccelerometerEvents([SensorEventInterval sensorEventInterval = SensorEventInterval.low]) {
  if (_userAccelerometerEvents == null) {
    _userAccelerometerEvents = _userAccelerometerEventChannel
        .receiveBroadcastStream(Codec.encodeSensorEventInterval(sensorEventInterval))
        .map((dynamic event) =>
            _listToUserAccelerometerEvent(event.cast<double>()));
  }
  return _userAccelerometerEvents;
}
