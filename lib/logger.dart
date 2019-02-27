import 'package:http/http.dart' as http;
import 'package:device_info/device_info.dart';
import 'dart:io' show Platform;

class Logger {
  static final Logger _singleton = new Logger._internal();

  factory Logger() {
    return _singleton;
  }

  Logger._internal();

  static const String _csvHeader = "timestamp,x,y,z,latitude,longitude,altitude,accuracy,traveled_distance,rel_alt_gain,rel_alt_loss,step_count\n";
  List _entries = [];

  double _latitude = 0.0;
  double _longitude = 0.0;
  double _accuracy = 9999.0;
  double _altitude = 0.0;
  double _relativeAltitudeGain = 0.0;
  double _relativeAltitudeLoss = 0.0;
  double _traveledDistance = 0.0;
  int _stepCount = 0;
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  int _accuracyFilter;
  int _distanceFilter;

  setLatitudeLongitude(double latitude, double longitude) {
    this._latitude = latitude;
    this._longitude = longitude;
  }

  setAccuracy(double accuracy) {
    this._accuracy = accuracy;
  }

  setAltitude(double altitude) {
    this._altitude = altitude;
  }

  setRelativeAltitudes(double relativeAltitudeGain, double relativeAltitudeLoss) {
    this._relativeAltitudeGain = relativeAltitudeGain;
    this._relativeAltitudeLoss = relativeAltitudeLoss;
  }

  setTraveledDistance(double traveledDistance) {
    this._traveledDistance = traveledDistance;
  }

  setStepCount(int stepCount) {
    this._stepCount = stepCount;
  }

  setMotionData(double x, double y, double z) {
    this._x = x;
    this._y = y;
    this._z = z;
  }

  setAccuracyFilter(int accuracy) {
    _accuracyFilter = accuracy;
  }

  setDistanceFilter(int distance) {
    _distanceFilter = distance;
  }

  addEntry() {
    _entries.add("${DateTime.now().toString()},$_x,$_y,$_z,$_latitude,$_longitude,$_altitude,$_accuracy,$_traveledDistance,$_relativeAltitudeGain,$_relativeAltitudeLoss,$_stepCount");
  }

  clearEntries() {
    _latitude = 0.0;
    _longitude = 0.0;
    _accuracy = 9999.0;
    _traveledDistance = 0.0;
    _stepCount = 0;
    _x = 0.0;
    _y = 0.0;
    _z = 0.0;
    _entries.clear();
  }

  Future<bool> shareLog([String notes = ""]) async {
    String platform;
    String device;
    if (Platform.isAndroid) {
      platform = "Android";
      AndroidDeviceInfo androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      device = androidDeviceInfo.model;
    } else if (Platform.isIOS) {
      platform = "iOS";
      IosDeviceInfo iosDeviceInfo = await DeviceInfoPlugin().iosInfo;
      device = iosDeviceInfo.utsname.machine;
    } else {
      device = "device unknown";
    }

    String csvContent = _entries.join("\n");
    
    Uri uri = Uri.parse("https://imidist.uber.space/logs/saveLog/");
    http.MultipartRequest request = new http.MultipartRequest("POST", uri);
    if (notes.isNotEmpty) {
      request.fields['notes'] = "$platform, $device, $notes, accFilter${_accuracyFilter}m, distFilter${_distanceFilter}m";
    } else {
      request.fields['notes'] = "$platform, $device, accFilter${_accuracyFilter}m, distFilter${_distanceFilter}m";
    }
    request.files.add(new http.MultipartFile.fromString("csv", _csvHeader + csvContent));

    try {
      return await request.send().then((response) {
        if (response.statusCode == 200) {
          clearEntries();
          return true;
        } else {
          return false;
        }
      });
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

}
