// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.sensors;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/**
 * SensorsPlugin
 */
public class SensorsPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler {
    private static final String METHOD_CHANNEL_NAME = "plugins.flutter.io/sensors/method";
    private static final String ACCELEROMETER_CHANNEL_NAME =
            "plugins.flutter.io/sensors/accelerometer";
    private static final String GYROSCOPE_CHANNEL_NAME = "plugins.flutter.io/sensors/gyroscope";
    private static final String USER_ACCELEROMETER_CHANNEL_NAME =
            "plugins.flutter.io/sensors/user_accel";
    private static final String BAROMETER_CHANNEL_NAME =
            "plugins.flutter.io/sensors/barometer";
    private static final String MAGNETOMETER_CHANNEL_NAME =
            "plugins.flutter.io/sensors/magnetometer";

    private Context context;
    private MethodChannel methodChannel;
    private EventChannel accelerometerChannel;
    private EventChannel userAccelChannel;
    private EventChannel gyroscopeChannel;
    private EventChannel barometerChannel;
    private EventChannel magnetometerChannel;

    /**
     * Plugin registration.
     */
    @SuppressWarnings("deprecation")
    public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
        SensorsPlugin plugin = new SensorsPlugin();
        plugin.setupEventChannels(registrar.context(), registrar.messenger());
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL_NAME);
        methodChannel.setMethodCallHandler(this);
        setupEventChannels(context, binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        teardownEventChannels();
    }

    private void setupEventChannels(Context context, BinaryMessenger messenger) {
        accelerometerChannel = new EventChannel(messenger, ACCELEROMETER_CHANNEL_NAME);
        final StreamHandlerImpl accelerationStreamHandler =
                new StreamHandlerImpl(
                        (SensorManager) context.getSystemService(context.SENSOR_SERVICE),
                        Sensor.TYPE_ACCELEROMETER,
                        true);
        accelerometerChannel.setStreamHandler(accelerationStreamHandler);

        userAccelChannel = new EventChannel(messenger, USER_ACCELEROMETER_CHANNEL_NAME);
        final StreamHandlerImpl linearAccelerationStreamHandler =
                new StreamHandlerImpl(
                        (SensorManager) context.getSystemService(context.SENSOR_SERVICE),
                        Sensor.TYPE_LINEAR_ACCELERATION,
                        true);
        userAccelChannel.setStreamHandler(linearAccelerationStreamHandler);

        gyroscopeChannel = new EventChannel(messenger, GYROSCOPE_CHANNEL_NAME);
        final StreamHandlerImpl gyroScopeStreamHandler =
                new StreamHandlerImpl(
                        (SensorManager) context.getSystemService(context.SENSOR_SERVICE),
                        Sensor.TYPE_GYROSCOPE,
                        true);
        gyroscopeChannel.setStreamHandler(gyroScopeStreamHandler);

        barometerChannel = new EventChannel(messenger, BAROMETER_CHANNEL_NAME);
        final StreamHandlerImpl barometerStreamHandler =
                new StreamHandlerImpl(
                        (SensorManager) context.getSystemService(context.SENSOR_SERVICE),
                        Sensor.TYPE_PRESSURE,
                        false);
        barometerChannel.setStreamHandler(barometerStreamHandler);

        magnetometerChannel = new EventChannel(messenger, MAGNETOMETER_CHANNEL_NAME);
        final StreamHandlerImpl magnometerStreamHandler =
                new StreamHandlerImpl(
                        (SensorManager) context.getSystemService(context.SENSOR_SERVICE),
                        Sensor.TYPE_MAGNETIC_FIELD,
                        true);
        magnetometerChannel.setStreamHandler(magnometerStreamHandler);
    }

    private void teardownEventChannels() {
        accelerometerChannel.setStreamHandler(null);
        userAccelChannel.setStreamHandler(null);
        gyroscopeChannel.setStreamHandler(null);
        barometerChannel.setStreamHandler(null);
        magnetometerChannel.setStreamHandler(null);
        methodChannel.setMethodCallHandler(null);
        context = null;
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("isBaroSupported")) {
            final SensorManager manager = (SensorManager) context.getSystemService(context.SENSOR_SERVICE);
            final boolean hasBarometer = manager.getDefaultSensor(Sensor.TYPE_PRESSURE) != null;
            result.success(hasBarometer);
        }
    }
}
