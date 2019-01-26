import 'package:http/http.dart' as http;

class Logger {
  static final Logger _singleton = new Logger._internal();

  factory Logger() {
    return _singleton;
  }

  Logger._internal();

  static const String _csvHeader = "timestamp,x,y,z,latitude,longitude,accuracy,traveled_distance,step_count\n";
  List _entries = [];

  String platform = "";

  double _latitude = 0.0;
  double _longitude = 0.0;
  double _accuracy = 9999.0;
  double _traveledDistance = 0.0;
  int _stepCount = 0;
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  setPlatform(String platform) {
    this.platform = platform;
  }

  setLatitudeLongitude(double latitude, double longitude) {
    this._latitude = latitude;
    this._longitude = longitude;
  }

  setAccuracy(double accuracy) {
    this._accuracy = accuracy;
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

  addEntry() {
    _entries.add("${DateTime.now().toString()},$_x,$_y,$_z,$_latitude,$_longitude,$_accuracy,$_traveledDistance,$_stepCount");
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
    String csvContent = _entries.join("\n");
    
    Uri uri = Uri.parse("https://imidist.uber.space/logs/saveLog/");
    http.MultipartRequest request = new http.MultipartRequest("POST", uri);
    if (notes.isNotEmpty) {
      request.fields['notes'] = platform + ", " + notes;
    } else {
      request.fields['notes'] = platform;
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
