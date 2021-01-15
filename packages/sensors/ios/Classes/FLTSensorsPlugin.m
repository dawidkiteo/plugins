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

    FLTSensorsStreamHandler* deviceMotionStreamHandler = [[FLTSensorsStreamHandler alloc] init];
    FlutterEventChannel* deviceMotionChannel = [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/sensors/motion" binaryMessenger:[registrar messenger]];
    [deviceMotionChannel setStreamHandler:deviceMotionStreamHandler];
}

@end

const double GRAVITY = 9.8;
const double MAGNETOMETER_FACTOR = 0.000001;
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

static void sendTriplet(Float64 x, Float64 y, Float64 z, uint64_t timestamp, FlutterEventSink sink) {
    NSDictionary *dictionary = @{
        [NSNumber numberWithInt: 0] : [NSNumber numberWithFloat: x],
        [NSNumber numberWithInt: 1] : [NSNumber numberWithFloat: y],
        [NSNumber numberWithInt: 2] : [NSNumber numberWithFloat: z],
        [NSNumber numberWithInt: 3] : [NSNumber numberWithUnsignedLongLong: timestamp]
    };
    sink(dictionary);
}

static uint64_t currentTimestamp() {
    if (@available(iOS 10.0, *)) {
        return clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW);
    } else {
        return 0;// Fallback on earlier versions
    }
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
        uint64_t timestamp = currentTimestamp();
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
        uint64_t timestamp = currentTimestamp();
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
        uint64_t timestamp = currentTimestamp();
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
        uint64_t timestamp = currentTimestamp();
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

@implementation FLTSensorsStreamHandler

uint64_t startTimestamp = 0;
uint64_t timeStep = 0;
uint64_t offset = 0;
bool finished;

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _initMotionManager();

    if (arguments != nil) {
        double fixedInterval = 1.0 / (double) ([arguments intValue] * 2);
        [_motionManager setDeviceMotionUpdateInterval: fixedInterval];
        
        double expectedInterval = 1.0 / (double) [arguments intValue];
        timeStep = expectedInterval * 1000 * 1000000;
    }
    
    startTimestamp = 0;
    offset = 0;
    finished = false;
    
    [_motionManager
     startDeviceMotionUpdatesUsingReferenceFrame: CMAttitudeReferenceFrameXTrueNorthZVertical
     toQueue:[[NSOperationQueue alloc] init]
     withHandler:^(CMDeviceMotion* data, NSError* error) {
        if (finished) return;
        
        uint64_t timestamp = currentTimestamp();
        
        if (startTimestamp == 0) {
            startTimestamp = timestamp;
        }
        
        uint64_t expectedOffset = (timestamp - startTimestamp) / timeStep;
        if (offset > expectedOffset) {
            return;
        }
        
        offset++;
        
        Float64 accX = (data.userAcceleration.x + data.gravity.x) * -GRAVITY;
        Float64 accY = (data.userAcceleration.y + data.gravity.y) * -GRAVITY;
        Float64 accZ = (data.userAcceleration.z + data.gravity.z) * -GRAVITY;

        Float64 gyrX = data.rotationRate.x;
        Float64 gyrY = data.rotationRate.y;
        Float64 gyrZ = data.rotationRate.z;

        Float64 magX = data.magneticField.field.x * MAGNETOMETER_FACTOR;
        Float64 magY = data.magneticField.field.y * MAGNETOMETER_FACTOR;
        Float64 magZ = data.magneticField.field.z * MAGNETOMETER_FACTOR;

        NSMutableData* event = [NSMutableData dataWithCapacity:9 * sizeof(Float64)];

        [event appendBytes:&accX length:sizeof(Float64)];
        [event appendBytes:&accY length:sizeof(Float64)];
        [event appendBytes:&accZ length:sizeof(Float64)];

        [event appendBytes:&gyrX length:sizeof(Float64)];
        [event appendBytes:&gyrY length:sizeof(Float64)];
        [event appendBytes:&gyrZ length:sizeof(Float64)];

        [event appendBytes:&magX length:sizeof(Float64)];
        [event appendBytes:&magY length:sizeof(Float64)];
        [event appendBytes:&magZ length:sizeof(Float64)];

        eventSink([FlutterStandardTypedData typedDataWithFloat64:event]);
    }];
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    finished = true;
    [_motionManager stopDeviceMotionUpdates];
    return nil;
}

@end
