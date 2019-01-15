# sensors

A Flutter plugin to access the accelerometer and gyroscope sensors.


## Usage

To use this plugin, add `sensors` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).


### Example

``` dart
import 'package:sensors/sensors.dart';

getAccelerometerEvents().listen((AccelerometerEvent event) {
 // Do something with the event.
});

getGyroscopeEvents().listen((GyroscopeEvent event) {
 // Do something with the event.
});

// Optionally, specify the sample rate by using
getAccelerometerEvents(SensorEventInterval.medium).listen((AccelerometerEvent event) {
 // Sample rate available in .low (default), .medium, and .high. Analogously for gyroscope events.
 // Do something with the event.
});
```