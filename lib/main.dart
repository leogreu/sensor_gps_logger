import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:sensor_gps_logger/location.dart';
import 'package:sensor_gps_logger/motion.dart';
import 'package:sensor_gps_logger/logger.dart';
import 'package:pedometer/pedometer.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor GPS Logger',
      theme: ThemeData(
        primarySwatch: Colors.blue
      ),
      home: MyHomePage(),
      debugShowCheckedModeBanner: false
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Icon buttonIcon;
  String buttonText;
  Color buttonColor;

  bool isLocating;
  bool isLogging;

  double accuracy = 9999.0;
  double relativeAltitudeGain = 0.0;
  double relativeAltitudeLoss = 0.0;
  double traveledDistance = 0.0;

  int stepCountStartAndroid = 0;
  bool stepCountStartSetAndroid = false;
  int stepCount = 0;

  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  int accuracyFilter;
  int distanceFilter;

  StreamSubscription<PositionEvent> accuracyStreamSubscription;
  StreamSubscription<DistanceEvent> traveledDistanceStreamSubscription;
  StreamSubscription<MotionEvent> motionStreamSubscription;
  StreamSubscription<int> stepCounterStreamSubscription;

  toggleLogging() {
    setState(() {
      if (isLocating == null || isLogging) {
        buttonIcon = Icon(Icons.location_on);
        buttonText = "Start Locating";
        buttonColor = Colors.blue;
        isLocating = false;
        isLogging = false;
        accuracy = 9999.0;
        traveledDistance = 0.0;
        relativeAltitudeGain = 0.0;
        relativeAltitudeLoss = 0.0;
        stepCount = 0;
        if (traveledDistanceStreamSubscription != null || accuracyStreamSubscription != null) {
          Location().cancelPositionStream();
          accuracyStreamSubscription.cancel();
          accuracyStreamSubscription = null;
          traveledDistanceStreamSubscription.cancel();
          traveledDistanceStreamSubscription = null;
          stepCounterStreamSubscription.cancel();
          stepCounterStreamSubscription = null;
          motionStreamSubscription.pause();
          askToSendLog();
        }
      } else if (!isLocating) {
        Location().setAccuracyFilter(accuracyFilter);
        Location().setDistanceFilter(distanceFilter);
        Logger().setAccuracyFilter(accuracyFilter);
        Logger().setDistanceFilter(distanceFilter);
        accuracyStreamSubscription = Location().getAccuracyStream().listen((PositionEvent positionEvent) {
          setState(() {
            this.accuracy = positionEvent.accuracy;
          });
          Logger().setAccuracy(positionEvent.accuracy);
          Logger().setLatitudeLongitude(positionEvent.latitude, positionEvent.longitude);
          Logger().setAltitude(positionEvent.altitude);
        });
        isLocating = true;
        buttonIcon = Icon(Icons.play_arrow);
        buttonText = "Start Logging";
        buttonColor = Colors.green;
        isLogging = false;
      } else if (!isLogging && isLocating) {
        buttonIcon = Icon(Icons.stop);
        buttonText = "Stop Logging";
        buttonColor = Colors.red;
        isLogging = true;
        stepCountStartAndroid = 0;
        stepCountStartSetAndroid = false;
        traveledDistanceStreamSubscription = Location().getTraveledDistanceStream().listen((DistanceEvent distanceEvent) {
          this.traveledDistance = distanceEvent.traveledDistance;
          this.relativeAltitudeGain = distanceEvent.relativeAltitudeGain;
          this.relativeAltitudeLoss = distanceEvent.relativeAltitudeLoss;
          Logger().setTraveledDistance(traveledDistance);
          Logger().setRelativeAltitudes(relativeAltitudeGain, relativeAltitudeLoss);
        });
        stepCounterStreamSubscription = Pedometer().stepCountStream.listen((int stepCount){
          if (!stepCountStartSetAndroid && Platform.isAndroid) {
            stepCountStartAndroid = stepCount;
            stepCountStartSetAndroid = true;
          }
          this.stepCount = stepCount - stepCountStartAndroid;
          Logger().setStepCount(stepCount - stepCountStartAndroid);
        });
      }
    });
  }

  @override
    void initState() {
      super.initState();

      toggleLogging();

      motionStreamSubscription = Motion().getMotionStream().listen((MotionEvent motionEvent) {
        setState(() {
          this.x = motionEvent.x;
          this.y = motionEvent.y;
          this.z = motionEvent.z;
        });
        Logger().setMotionData(x, y, z);
        if (isLogging) {
          Logger().addEntry();
        }
      });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location and Motion Logger"),
      ),
      body: ListView(
        children: <Widget>[
          Card(
            margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Container(
              margin: EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text("Location Sensor", style: TextStyle(fontSize: 18)),
                  Text("(GPS)", style: TextStyle(fontSize: 12)),
                  Divider(height: 20.0),
                  Stepper(10, "Accuracy filter", accuracyFilterCallback),
                  Stepper(5, "Distance filter", distanceFilterCallback),
                  Divider(height: 20.0),
                  Text("Accuracy: ${accuracy.toStringAsFixed(2)} m"),
                  Text("Traveled Distance: ${traveledDistance.toStringAsFixed(1)} m"),
                  Text("Rel. Altitude Gain: ${relativeAltitudeGain.toStringAsFixed(1)} m"),
                  Text("Rel. Altitude Loss: ${relativeAltitudeLoss.toStringAsFixed(1)} m")
                ],
              )
            )
          ),
          Card(
            margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Container(
              margin: EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text("Motion Sensor", style: TextStyle(fontSize: 18)),
                  Text("(Accelerometer)", style: TextStyle(fontSize: 12)),
                  Divider(height: 20.0),
                  Text("X: ${x.toStringAsFixed(4)}"),
                  Text("Y: ${y.toStringAsFixed(4)}"),
                  Text("Z: ${z.toStringAsFixed(4)}")
                ],
              )
            )
          ),
          Card(
            margin: EdgeInsets.only(top: 10.0, left: 10.0, right: 10.0),
            child: Container(
              margin: EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text("Step Count", style: TextStyle(fontSize: 18)),
                  Text("(Native via API)", style: TextStyle(fontSize: 12)),
                  Divider(height: 20.0),
                  Text("Steps: $stepCount"),
                ],
              )
            )
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: toggleLogging,
        icon: buttonIcon,
        label: Text(buttonText),
        backgroundColor: buttonColor
      )
    );
  }

  void askToSendLog() {
    String notes = "";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Send log?"),
          content: new TextField(
            decoration: new InputDecoration(hintText: "Notes (optional)"),
            onChanged: (String input) {
              notes = input;
            }
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Logger().clearEntries();
                motionStreamSubscription.resume();
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Send"),
              onPressed: () {
                asynchronouslySendLog(notes);
                Navigator.of(context).pop();
              },
            )
          ],
        );
      },
    );
  }

  asynchronouslySendLog (String notes) async {
    bool result = await Logger().shareLog(notes);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text(result?"Success":"Error"),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Okay"),
              onPressed: () {
                Navigator.of(context).pop();
                if (!result) {
                  askToSendLog();
                } else {
                  motionStreamSubscription.resume();
                }
              }
            )
          ]
        );
      },
    );
  }

  accuracyFilterCallback(int accuracy) {
    accuracyFilter = accuracy;
  }

  distanceFilterCallback(int distance) {
    distanceFilter = distance;
  }

  @override
    void dispose() {
      if (accuracyStreamSubscription != null) {
        accuracyStreamSubscription.cancel();
        accuracyStreamSubscription = null;
      }

      if (traveledDistanceStreamSubscription != null) {
        traveledDistanceStreamSubscription.cancel();
        traveledDistanceStreamSubscription = null;
      }

      if (motionStreamSubscription != null) {
        motionStreamSubscription.cancel();
        motionStreamSubscription = null;
      }

      if (stepCounterStreamSubscription != null) {
        stepCounterStreamSubscription.cancel();
        stepCounterStreamSubscription = null;
      }

      super.dispose();
    }
}

class Stepper extends StatefulWidget {
  final Function(int) _callback;
  final String _name;
  final int _startCounter;

  Stepper(this._startCounter, this._name, this._callback);

  @override
  _StepperState createState() => _StepperState();
}

class _StepperState extends State<Stepper> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();

    setState(() {
      _counter = widget._startCounter;
    });

    widget._callback(_counter);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text("${widget._name}:"),
        ButtonTheme(
          minWidth: 28.0,
          height: 28.0,
          child: FlatButton(
            onPressed: _decrement,
            child: Text("-", style: TextStyle(color: Colors.blue)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap
          )
        ),
        Text("${_counter}m"),
        ButtonTheme(
          minWidth: 28.0,
          height: 28.0,
          child: FlatButton(
            onPressed: _increment,
            child: Text("+", style: TextStyle(color: Colors.blue)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap
          )
        )
      ],
    );
  }

  void _increment() {
    setState(() {
      _counter++;
    });
    widget._callback(_counter);
  }

  void _decrement() {
    if (_counter > 0) {
      setState(() {
        _counter--;
      });
      widget._callback(_counter);
    }
  }
}
