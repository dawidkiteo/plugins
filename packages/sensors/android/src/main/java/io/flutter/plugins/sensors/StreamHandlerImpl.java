// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.sensors;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

import io.flutter.plugin.common.EventChannel;

class StreamHandlerImpl implements EventChannel.StreamHandler {

    private SensorEventListener sensorEventListener;
    private final SensorManager sensorManager;
    private final Sensor sensor;

    StreamHandlerImpl(SensorManager sensorManager, int sensorType) {
        this.sensorManager = sensorManager;
        sensor = sensorManager.getDefaultSensor(sensorType);
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        int samplingPeriod = SensorManager.SENSOR_DELAY_FASTEST;
        if (arguments != null) {
            samplingPeriod = 1000000 / ((int) arguments);
        }

        Log.d("StreamHandlerImpl", sensor.toString() + " - sampling period: " + samplingPeriod);

        sensorEventListener = createSensorEventListener(events);
        sensorManager.registerListener(sensorEventListener, sensor, samplingPeriod);
    }

    @Override
    public void onCancel(Object arguments) {
        sensorManager.unregisterListener(sensorEventListener);
    }

    SensorEventListener createSensorEventListener(final EventChannel.EventSink events) {
        return new SensorEventListener() {
            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
            }

            @Override
            public void onSensorChanged(SensorEvent event) {
                double[] sensorValues = new double[event.values.length];
                for (int i = 0; i < event.values.length; i++) {
                    sensorValues[i] = event.values[i];
                }
                events.success(sensorValues);
            }
        };
    }
}
