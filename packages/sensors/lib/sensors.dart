// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

const MethodChannel _methodChannel = MethodChannel('plugins.flutter.io/sensors/method');

const EventChannel _accelerometerEventChannel = EventChannel('plugins.flutter.io/sensors/accelerometer');

const EventChannel _userAccelerometerEventChannel = EventChannel('plugins.flutter.io/sensors/user_accel');

const EventChannel _gyroscopeEventChannel = EventChannel('plugins.flutter.io/sensors/gyroscope');

const EventChannel _barometerEventChannel = EventChannel('plugins.flutter.io/sensors/barometer');

const EventChannel _magnetometerEventChannel = EventChannel('plugins.flutter.io/sensors/magnetometer');

/// Discrete reading from an accelerometer. Accelerometers measure the velocity
/// of the device. Note that these readings include the effects of gravity. Put
/// simply, you can use accelerometer readings to tell if the device is moving in
/// a particular direction.
class AccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  AccelerometerEvent(this.x, this.y, this.z, this.timestamp);

  /// Acceleration force along the x axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (including gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (including gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  /// Timestamp in milliseconds
  final int timestamp;

  @override
  String toString() => '[AccelerometerEvent (x: $x, y: $y, z: $z)]';
}

/// Discrete reading from a gyroscope. Gyroscopes measure the rate or rotation of
/// the device in 3D space.
class GyroscopeEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  GyroscopeEvent(this.x, this.y, this.z, this.timestamp);

  /// Rate of rotation around the x axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "pitch". The top of the device will tilt towards or away from the
  /// user as this value changes.
  final double x;

  /// Rate of rotation around the y axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "yaw". The lengthwise edge of the device will rotate towards or away from
  /// the user as this value changes.
  final double y;

  /// Rate of rotation around the z axis measured in rad/s.
  ///
  /// When the device is held upright, this can also be thought of as describing
  /// "roll". When this changes the face of the device should remain facing
  /// forward, but the orientation will change from portrait to landscape and so
  /// on.
  final double z;

  /// Timestamp in milliseconds
  final int timestamp;

  @override
  String toString() => '[GyroscopeEvent (x: $x, y: $y, z: $z)]';
}

/// Like [AccelerometerEvent], this is a discrete reading from an accelerometer
/// and measures the velocity of the device. However, unlike
/// [AccelerometerEvent], this event does not include the effects of gravity.
class UserAccelerometerEvent {
  /// Contructs an instance with the given [x], [y], and [z] values.
  UserAccelerometerEvent(this.x, this.y, this.z, this.timestamp);

  /// Acceleration force along the x axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving to the right and negative mean it is moving to the left.
  final double x;

  /// Acceleration force along the y axis (excluding gravity) measured in m/s^2.
  ///
  /// When the device is held upright facing the user, positive values mean the
  /// device is moving towards the sky and negative mean it is moving towards
  /// the ground.
  final double y;

  /// Acceleration force along the z axis (excluding gravity) measured in m/s^2.
  ///
  /// This uses a right-handed coordinate system. So when the device is held
  /// upright and facing the user, positive values mean the device is moving
  /// towards the user and negative mean it is moving away from them.
  final double z;

  /// Timestamp in milliseconds
  final int timestamp;

  @override
  String toString() => '[UserAccelerometerEvent (x: $x, y: $y, z: $z)]';
}

/// Reading from barometer that returns atmospheric pressure in pressure (millibar)
class BarometerEvent {
  /// Atmospheric pressure
  final double pressure;

  /// Contructs an instance with the given pressure
  BarometerEvent(this.pressure);

  @override
  String toString() => '[BarometerEvent (pressure: $pressure)]';
}

class MagnetometerEvent {
  final double x;
  final double y;
  final double z;

  /// Timestamp in milliseconds
  final int timestamp;

  MagnetometerEvent(this.x, this.y, this.z, this.timestamp);

  @override
  String toString() => '[MagnetometerEvent (x: $x, y: $y, z: $z)]';
}

AccelerometerEvent _listToAccelerometerEvent(Map<dynamic, dynamic> map) {
  return AccelerometerEvent(map[0] as double, map[1] as double, map[2] as double, map[3] as int);
}

UserAccelerometerEvent _listToUserAccelerometerEvent(Map<dynamic, dynamic> map) {
  return UserAccelerometerEvent(map[0] as double, map[1] as double, map[2] as double, map[3] as int);
}

GyroscopeEvent _listToGyroscopeEvent(Map<dynamic, dynamic> map) {
  return GyroscopeEvent(map[0] as double, map[1] as double, map[2] as double, map[3] as int);
}

BarometerEvent _listToBarometerEvent(List<double> list) {
  return BarometerEvent(list[0]);
}

MagnetometerEvent _listToMagnetometerEvent(Map<dynamic, dynamic> map) {
  return MagnetometerEvent(map[0] as double, map[1] as double, map[2] as double, map[3] as int);
}

Stream<AccelerometerEvent> _accelerometerEvents;
Stream<GyroscopeEvent> _gyroscopeEvents;
Stream<UserAccelerometerEvent> _userAccelerometerEvents;
Stream<BarometerEvent> _barometerEvents;
Stream<MagnetometerEvent> _magnetometerEvents;

/// A broadcast stream of events from the device accelerometer.
Stream<AccelerometerEvent> accelerometerEvents({int frequency}) {
  if (_accelerometerEvents == null) {
    _accelerometerEvents = _accelerometerEventChannel
        .receiveBroadcastStream(frequency)
        .map((dynamic event) => _listToAccelerometerEvent(event));
  }
  return _accelerometerEvents;
}

/// A broadcast stream of events from the device gyroscope.
Stream<GyroscopeEvent> gyroscopeEvents({int frequency}) {
  if (_gyroscopeEvents == null) {
    _gyroscopeEvents =
        _gyroscopeEventChannel.receiveBroadcastStream(frequency).map((dynamic event) => _listToGyroscopeEvent(event));
  }
  return _gyroscopeEvents;
}

/// Events from the device accelerometer with gravity removed.
Stream<UserAccelerometerEvent> userAccelerometerEvents({int frequency}) {
  if (_userAccelerometerEvents == null) {
    _userAccelerometerEvents = _userAccelerometerEventChannel
        .receiveBroadcastStream(frequency)
        .map((dynamic event) => _listToUserAccelerometerEvent(event));
  }
  return _userAccelerometerEvents;
}

/// A broadcast stream of events from the device barometer.
Stream<BarometerEvent> barometerEvents({int frequency}) {
  if (_barometerEvents == null) {
    _barometerEvents = _barometerEventChannel
        .receiveBroadcastStream(frequency)
        .map((dynamic event) => _listToBarometerEvent(event.cast<double>()));
  }
  return _barometerEvents;
}

/// A broadcast stream of values recorded by magnetometer
Stream<MagnetometerEvent> magnetometerEvents({int frequency}) {
  if (_magnetometerEvents == null) {
    _magnetometerEvents = _magnetometerEventChannel
        .receiveBroadcastStream(frequency)
        .map((dynamic event) => _listToMagnetometerEvent(event));
  }
  return _magnetometerEvents;
}

Future<bool> isBarometerSupported() async {
  if (Platform.isIOS) {
    return true;
  } else {
    return _methodChannel.invokeMethod('isBaroSupported');
  }
}
