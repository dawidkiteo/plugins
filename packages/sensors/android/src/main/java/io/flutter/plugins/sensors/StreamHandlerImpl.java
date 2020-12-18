// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.sensors;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

import java.util.HashMap;

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
        if (sensorManager == null) {
            return;
        }

        int samplingPeriod = SensorManager.SENSOR_DELAY_FASTEST;
        if (arguments != null) {
            samplingPeriod = 1000000 / ((int) arguments);
        }

        if (withTimestamps) {
            sensorEventListener = createSensorEventListenerWithTimestamps(events);
        } else {
            sensorEventListener = createSensorEventListener(events);
        }

        sensorManager.registerListener(sensorEventListener, sensor, samplingPeriod);
    }

    @Override
    public void onCancel(Object arguments) {
        if (sensorManager == null) {
            return;
        }
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
                final long timestamp = System.nanoTime();
                final HashMap<Integer, Object> valuesMap = new HashMap<>();
                valuesMap.put(0, event.values[0]);
                valuesMap.put(1, event.values[1]);
                valuesMap.put(2, event.values[2]);
                valuesMap.put(3, timestamp);
                events.success(valuesMap);
            }
        };
    }
}
