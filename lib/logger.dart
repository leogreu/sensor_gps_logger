import 'package:http/http.dart' as http;

class Logger {
  static final Logger _singleton = new Logger._internal();

  factory Logger() {
    return _singleton;
  }

  Logger._internal();

  static const String _csvHeader = "timestamp,x,y,z,traveled_distance,accuracy\n";
  List entries = [];

  double _accuracy = 9999.0;
  double _traveledDistance = 0.0;
  double _x = 0.0;
  double _y = 0.0;
  double _z = 0.0;

  setAccuracy(double accuracy) {
    this._accuracy = accuracy;
  }

  setTraveledDistance(double traveledDistance) {
    this._traveledDistance = traveledDistance;
  }

  setMotionData(double x, double y, double z) {
    this._x = x;
    this._y = y;
    this._z = z;
  }

  addEntry() {
    entries.add("${DateTime.now().toString()},$_x,$_y,$_z,$_traveledDistance,$_accuracy");
  }

  Future<bool> shareLog([String notes = ""]) async {
    String csvContent = entries.join("\n");
    
    Uri uri = Uri.parse("https://imidist.uber.space/logs/saveLog/");
    http.MultipartRequest request = new http.MultipartRequest("POST", uri);
    request.fields['notes'] = notes;
    request.files.add(new http.MultipartFile.fromString("csv", _csvHeader + csvContent));

    try {
      return await request.send().then((response) {
        if (response.statusCode == 200) {
          entries.clear();
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
