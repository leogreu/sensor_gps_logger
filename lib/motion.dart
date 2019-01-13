import 'package:sensors/sensors.dart';
import 'dart:async';

class Motion {
  static final Motion _singleton = new Motion._internal();

  factory Motion() {
    return _singleton;
  }

  Motion._internal();

  StreamSubscription<AccelerometerEvent> _accelerometerStreamSubscription;
  double _lastX = 0.0;
  double _lastY = 0.0;
  double _lastZ = 0.0;

  StreamController<MotionEvent> _accelerometerStreamController;

  int _eventsPerSecond = 0;

  void _initiateMotionStream() {
    _accelerometerStreamSubscription = accelerometerEvents.listen((AccelerometerEvent accelerometerEvent) {
      _lastX = accelerometerEvent.x;
      _lastY = accelerometerEvent.y;
      _lastZ = accelerometerEvent.z;
      _eventsPerSecond++;
    });

    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      print("Sensor events per second: " + _eventsPerSecond.toString());
      _eventsPerSecond = 0;
    });

    Timer.periodic(Duration(milliseconds: 20), (Timer timer) {
      if (_accelerometerStreamController != null && _accelerometerStreamController.hasListener) {
        _accelerometerStreamController.sink.add(MotionEvent(_lastX, _lastY, _lastZ));
      } else if (_accelerometerStreamController != null) {
        _accelerometerStreamSubscription.cancel();
        _accelerometerStreamController.close();
        _accelerometerStreamSubscription = null;
        _accelerometerStreamController = null;
        timer.cancel();
      }
    });
  }

  Stream<MotionEvent> getMotionStream() {
    if (_accelerometerStreamSubscription == null) {
      _initiateMotionStream();
    }

    if (_accelerometerStreamController == null) {
      _accelerometerStreamController = StreamController.broadcast();
    }

    return _accelerometerStreamController.stream;
  }

}

class MotionEvent {
  final double x;
  final double y;
  final double z;

  MotionEvent(this.x, this.y, this.z);
}
