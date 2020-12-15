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
    private final boolean withTimestamps;

    StreamHandlerImpl(SensorManager sensorManager, int sensorType, boolean withTimestamps) {
        this.sensorManager = sensorManager;
        sensor = sensorManager.getDefaultSensor(sensorType);
        this.withTimestamps = withTimestamps;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        int samplingPeriod = SensorManager.SENSOR_DELAY_FASTEST;
        if (arguments != null) {
            samplingPeriod = 1000000 / ((int) arguments);
        }

        Log.d("StreamHandlerImpl", sensor.toString() + " - sampling period: " + samplingPeriod);

        if (withTimestamps) {
            sensorEventListener = createSensorEventListenerWithTimestamps(events);
        } else {
            sensorEventListener = createSensorEventListener(events);
        }

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

    SensorEventListener createSensorEventListenerWithTimestamps(final EventChannel.EventSink events) {
        return new SensorEventListener() {
            @Override
            public void onAccuracyChanged(Sensor sensor, int accuracy) {
            }

            @Override
            public void onSensorChanged(SensorEvent event) {
                final double timestamp = (double) System.nanoTime() / 1000000;
                double[] sensorValues = new double[event.values.length + 1];
                sensorValues[event.values.length] = timestamp;
                for (int i = 0; i < event.values.length; i++) {
                    sensorValues[i] = event.values[i];
                }
                events.success(sensorValues);
            }
        };
    }
}
