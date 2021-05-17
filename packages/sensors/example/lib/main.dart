// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';

import 'snake.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int _snakeRows = 20;
  static const int _snakeColumns = 20;
  static const double _snakeCellSize = 10.0;

  int _barometerStartTimestamp;
  int _barometerProbes = 0;
  double _barometerPerSecond = 0;

  int _accStartTimestamp;
  int _accProbes = 0;
  double _accPerSecond = 0;

  int _gyroStartTimestamp;
  int _gyroProbes = 0;
  double _gyroPerSecond = 0;

  int _magStartTimestamp;
  int _magProbes = 0;
  double _magPerSecond = 0;

  List<double> _accelerometerValues;
  List<double> _userAccelerometerValues;
  List<double> _gyroscopeValues;
  List<double> _barometerValues;
  List<double> _magnetometerValues;
  List<StreamSubscription<dynamic>> _streamSubscriptions = <StreamSubscription<dynamic>>[];

  @override
  Widget build(BuildContext context) {
    final List<String> accelerometer = _accelerometerValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    final List<String> gyroscope = _gyroscopeValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    final List<String> userAccelerometer = _userAccelerometerValues?.map((double v) => v.toStringAsFixed(1))?.toList();
    final List<String> barometer = _barometerValues?.map((e) => e.toStringAsFixed(1))?.toList();
    final List<String> magnetometer = _magnetometerValues?.map((e) => e.toStringAsFixed(1))?.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(width: 1.0, color: Colors.black38),
              ),
              child: SizedBox(
                height: _snakeRows * _snakeCellSize,
                width: _snakeColumns * _snakeCellSize,
                child: Snake(
                  rows: _snakeRows,
                  columns: _snakeColumns,
                  cellSize: _snakeCellSize,
                ),
              ),
            ),
          ),
          Padding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Accelerometer: $accelerometer \n Probes per second: ${_accPerSecond.toStringAsFixed(2)}'),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          Padding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('UserAccelerometer: $userAccelerometer'),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          Padding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Gyroscope: $gyroscope \n Probes per second: ${_gyroPerSecond.toStringAsFixed(2)}'),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          Padding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Barometer: $barometer \n Probes per second: ${_barometerPerSecond.toStringAsFixed(2)}'),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
          ),
          Padding(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Magnetometer: $magnetometer \n Probes per second: ${_magPerSecond.toStringAsFixed(2)}'),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    _streamSubscriptions.add(accelerometerEvents(frequency: 50).listen((AccelerometerEvent event) {
      _accStartTimestamp ??= DateTime.now().millisecondsSinceEpoch;
      _accProbes++;
      _accPerSecond = _accProbes / ((DateTime.now().millisecondsSinceEpoch - _accStartTimestamp) / 1000);
      setState(() {
        _accelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions.add(gyroscopeEvents(frequency: 50).listen((GyroscopeEvent event) {
      _gyroStartTimestamp ??= DateTime.now().millisecondsSinceEpoch;
      _gyroProbes++;
      _gyroPerSecond = _gyroProbes / ((DateTime.now().millisecondsSinceEpoch - _gyroStartTimestamp) / 1000);
      setState(() {
        _gyroscopeValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions.add(userAccelerometerEvents(frequency: 50).listen((UserAccelerometerEvent event) {
      setState(() {
        _userAccelerometerValues = <double>[event.x, event.y, event.z];
      });
    }));
    _streamSubscriptions.add(barometerEvents(frequency: 1).listen((BarometerEvent event) {
      _barometerStartTimestamp ??= DateTime.now().millisecondsSinceEpoch;
      _barometerProbes++;
      _barometerPerSecond =
          _barometerProbes / ((DateTime.now().millisecondsSinceEpoch - _barometerStartTimestamp) / 1000);
      setState(() {
        _barometerValues = <double>[event.pressure];
      });
    }));
    _streamSubscriptions.add(magnetometerEvents(frequency: 50).listen((MagnetometerEvent event) {
      _magStartTimestamp ??= DateTime.now().millisecondsSinceEpoch;
      _magProbes++;
      _magPerSecond = _magProbes / ((DateTime.now().millisecondsSinceEpoch - _magStartTimestamp) / 1000);
      setState(() {
        _magnetometerValues = <double>[event.x, event.y, event.z];
      });
    }));
  }
}
