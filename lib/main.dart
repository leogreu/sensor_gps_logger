import 'package:flutter/material.dart';
import 'dart:async';

import 'package:sensor_gps_logger/location.dart';
import 'package:sensor_gps_logger/motion.dart';
import 'package:sensor_gps_logger/logger.dart';

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
  bool isLogging;

  double accuracy = 9999.0;
  double traveledDistance = 0.0;

  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  StreamSubscription<double> accuracyStreamSubscription;
  StreamSubscription<double> traveledDistanceStreamSubscription;
  StreamSubscription<MotionEvent> motionStreamSubscription;

  toggleLogging() {
    setState(() {
      if (isLogging == null || isLogging) {
        buttonIcon = Icon(Icons.play_arrow);
        buttonText = "Start Logging";
        buttonColor = Colors.blue;
        isLogging = false;
        if (traveledDistanceStreamSubscription != null) {
          traveledDistanceStreamSubscription.cancel();
          traveledDistanceStreamSubscription = null;
          motionStreamSubscription.pause();
          askToSendLog();
        }
      } else {
        buttonIcon = Icon(Icons.stop);
        buttonText = "Stop Logging";
        buttonColor = Colors.red;
        isLogging = true;
        traveledDistance = 0.0;
        traveledDistanceStreamSubscription = Location().getTraveledDistanceStream().listen((double traveledDistance) {
          this.traveledDistance = traveledDistance;
          Logger().setTraveledDistance(traveledDistance);    
        });
      }
    });
  }

  @override
    void initState() {
      super.initState();

      toggleLogging();

      accuracyStreamSubscription = Location().getAccuracyStream().listen((double accuracy) {
        setState(() {
          this.accuracy = accuracy;
          Logger().setAccuracy(accuracy);
        });
      });

      motionStreamSubscription = Motion().getMotionStream().listen((MotionEvent motionEvent) {
        setState(() {
          this.x = motionEvent.x;
          this.y = motionEvent.y;
          this.z = motionEvent.z;
          Logger().setMotionData(x, y, z);
          if (isLogging) {
            Logger().addEntry();
          }
        });
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
                  Text("Accuracy: ${accuracy.toStringAsFixed(2)}"),
                  Text("Traveled Distance: ${traveledDistance.toStringAsFixed(2)}")
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
                Navigator.of(context).pop();
                motionStreamSubscription.resume();
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

      super.dispose();
    }
}
