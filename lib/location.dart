import 'package:geolocator/geolocator.dart';
import 'dart:async';

class Location {
  static final Location _singleton = new Location._internal();

  factory Location() {
    return _singleton;
  }

  Location._internal();

  StreamSubscription<Position> _positionStreamSubscription;
  double _traveledDistance = 0.0;
  double _lastLatitude;
  double _lastLongitude;

  StreamController<AccuracyEvent> _accuracyStreamController;
  StreamController<double> _traveledDistanceStreamController;

  void _initiatePositionStream() {
    const LocationOptions locationOptions = LocationOptions(accuracy: LocationAccuracy.best, distanceFilter: 1);
    final Stream<Position> positionStream = Geolocator().getPositionStream(locationOptions);
    _positionStreamSubscription = positionStream.listen((Position position) {
      if (_accuracyStreamController != null && _accuracyStreamController.hasListener) {
        _accuracyStreamController.sink.add(AccuracyEvent(position.accuracy, position.latitude, position.longitude));
      } else if (_accuracyStreamController != null) {
        _accuracyStreamController.close();
        _accuracyStreamController = null;
      }

      if (_traveledDistanceStreamController != null && _traveledDistanceStreamController.hasListener) {
        _updateTraveledDistance(position.latitude, position.longitude);
      } else if (_traveledDistanceStreamController != null) {
        _traveledDistanceStreamController.close();
        _traveledDistanceStreamController = null;
        _traveledDistance = 0.0;
      }

      if (_accuracyStreamController == null && _traveledDistanceStreamController == null) {
        _positionStreamSubscription.cancel();
        _positionStreamSubscription = null;
      }

      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;
    });
  }

  _updateTraveledDistance(currentLatitude, currentLongitude) async {
    if (_lastLatitude == null || _lastLongitude == null) {
      return;
    }

    _traveledDistance += await Geolocator().distanceBetween(_lastLatitude, _lastLongitude, currentLatitude, currentLongitude);
    _traveledDistanceStreamController.sink.add(_traveledDistance);
  }

  Stream<AccuracyEvent> getAccuracyStream() {
    if (_positionStreamSubscription == null) {
      _initiatePositionStream();
    }

    if (_accuracyStreamController == null) {
      _accuracyStreamController = StreamController.broadcast();
    }

    return _accuracyStreamController.stream;
  }

  Stream<double> getTraveledDistanceStream() {
    if (_positionStreamSubscription == null) {
      _initiatePositionStream();
    }

    if (_traveledDistanceStreamController == null) {
      _traveledDistanceStreamController = StreamController.broadcast();
    }

    return _traveledDistanceStreamController.stream;
  }
}

class AccuracyEvent {
  final double accuracy;
  final double latitude;
  final double longitude;

  AccuracyEvent(this.accuracy, this.latitude, this.longitude);
}
