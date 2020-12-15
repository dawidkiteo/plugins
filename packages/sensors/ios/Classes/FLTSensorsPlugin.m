// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTSensorsPlugin.h"
#import <CoreMotion/CoreMotion.h>

@implementation FLTSensorsPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FLTAccelerometerStreamHandler* accelerometerStreamHandler =
    [[FLTAccelerometerStreamHandler alloc] init];
    FlutterEventChannel* accelerometerChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/sensors/accelerometer"
                              binaryMessenger:[registrar messenger]];
    [accelerometerChannel setStreamHandler:accelerometerStreamHandler];
    
    FLTUserAccelStreamHandler* userAccelerometerStreamHandler =
    [[FLTUserAccelStreamHandler alloc] init];
    FlutterEventChannel* userAccelerometerChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/sensors/user_accel"
                              binaryMessenger:[registrar messenger]];
    [userAccelerometerChannel setStreamHandler:userAccelerometerStreamHandler];
    
    FLTGyroscopeStreamHandler* gyroscopeStreamHandler = [[FLTGyroscopeStreamHandler alloc] init];
    FlutterEventChannel* gyroscopeChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/sensors/gyroscope"
                              binaryMessenger:[registrar messenger]];
    [gyroscopeChannel setStreamHandler:gyroscopeStreamHandler];
    
    FLTBarometerStreamHandler* barometerStreamHandler = [[FLTBarometerStreamHandler alloc] init];
    FlutterEventChannel* barometerChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/sensors/barometer"
                              binaryMessenger:[registrar messenger]];
    [barometerChannel setStreamHandler:barometerStreamHandler];
    
    FLTMagnetometerStreamHandler* magnetometerStreamHandler = [[FLTMagnetometerStreamHandler alloc] init];
    FlutterEventChannel* magnetometerChannel =
    [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/sensors/magnetometer"
                              binaryMessenger:[registrar messenger]];
    [magnetometerChannel setStreamHandler:magnetometerStreamHandler];
}

@end

const double GRAVITY = 9.8;
CMMotionManager* _motionManager;
CMAltimeter* _altimeter;

void _initMotionManager() {
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
    }
}

void _initAltimeter() {
    if (!_altimeter) {
        _altimeter = [[CMAltimeter alloc] init];
    }
}

static void sendTriplet(Float64 x, Float64 y, Float64 z, Float64 timestamp, FlutterEventSink sink) {
    NSMutableData* event = [NSMutableData dataWithCapacity:3 * sizeof(Float64)];
    [event appendBytes:&x length:sizeof(Float64)];
    [event appendBytes:&y length:sizeof(Float64)];
    [event appendBytes:&z length:sizeof(Float64)];
    [event appendBytes:&timestamp length:sizeof(Float64)];
    sink([FlutterStandardTypedData typedDataWithFloat64:event]);
}

static Float64 currentTimestamp() {
    return [[NSNumber numberWithFloat:[[[NSDate date] init] timeIntervalSince1970] * 1000] floatValue];
}

@implementation FLTAccelerometerStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _initMotionManager();

    if (arguments != nil) {
        double interval = 1.0 / [arguments intValue];
        [_motionManager setAccelerometerUpdateInterval: interval];
    }

    [_motionManager
     startAccelerometerUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMAccelerometerData* accelerometerData, NSError* error) {
        Float64 timestamp = currentTimestamp();
        CMAcceleration acceleration = accelerometerData.acceleration;
        // Multiply by gravity, and adjust sign values to
        // align with Android.
        sendTriplet(-acceleration.x * GRAVITY, -acceleration.y * GRAVITY,
                    -acceleration.z * GRAVITY, timestamp, eventSink);
    }];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [_motionManager stopAccelerometerUpdates];
    return nil;
}

@end

@implementation FLTUserAccelStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _initMotionManager();

    if (arguments != nil) {
        double interval = 1.0 / [arguments intValue];
        [_motionManager setAccelerometerUpdateInterval: interval];
    }

    [_motionManager
     startDeviceMotionUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMDeviceMotion* data, NSError* error) {
        Float64 timestamp = currentTimestamp();
        CMAcceleration acceleration = data.userAcceleration;
        // Multiply by gravity, and adjust sign values to align with Android.
        sendTriplet(-acceleration.x * GRAVITY, -acceleration.y * GRAVITY,
                    -acceleration.z * GRAVITY, timestamp, eventSink);
    }];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [_motionManager stopDeviceMotionUpdates];
    return nil;
}

@end

@implementation FLTGyroscopeStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _initMotionManager();

    if (arguments != nil) {
        double interval = 1.0 / [arguments intValue];
        [_motionManager setGyroUpdateInterval: interval];
    }

    [_motionManager
     startGyroUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMGyroData* gyroData, NSError* error) {
        Float64 timestamp = currentTimestamp();
        CMRotationRate rotationRate = gyroData.rotationRate;
        sendTriplet(rotationRate.x, rotationRate.y, rotationRate.z, timestamp, eventSink);

    }];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [_motionManager stopGyroUpdates];
    return nil;
}

@end

@implementation FLTBarometerStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _initAltimeter();

    [_altimeter
     startRelativeAltitudeUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMAltitudeData* altitudeData, NSError* error) {
        // Multiply by 10 to conver kilopascals to hPa (aligning with Android)
        NSNumber* pressure = [NSNumber numberWithDouble:[altitudeData.pressure doubleValue] * 10.0];
        NSArray* array = [NSArray arrayWithObjects: pressure, nil];
        eventSink(array);
    }];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [_altimeter stopRelativeAltitudeUpdates];
    return nil;
}

@end

@implementation FLTMagnetometerStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _initMotionManager();

    if (arguments != nil) {
        double interval = 1.0 / [arguments intValue];
        [_motionManager setMagnetometerUpdateInterval: interval];
    }

    [_motionManager
     startMagnetometerUpdatesToQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMMagnetometerData* magData, NSError* error) {
        Float64 timestamp = currentTimestamp();
        sendTriplet(magData.magneticField.x, magData.magneticField.y,
                    magData.magneticField.z, timestamp, eventSink);
    }];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    [_motionManager stopMagnetometerUpdates];
    return nil;
}

@end
