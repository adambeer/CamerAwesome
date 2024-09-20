//
//  SensorUtils.m
//  camerawesome
//
//  Created by Dimitri Dessus on 30/03/2023.
//

#import "SensorUtils.h"

@implementation SensorUtils

+ (PigeonSensorType)sensorTypeFromDeviceType:(AVCaptureDeviceType)type {
  if (type == AVCaptureDeviceTypeBuiltInTelephotoCamera) {
    return PigeonSensorTypeTelephoto;
  } else if (type == AVCaptureDeviceTypeBuiltInUltraWideCamera) {
    return PigeonSensorTypeUltraWideAngle;
  } else if (type == AVCaptureDeviceTypeBuiltInTrueDepthCamera) {
    return PigeonSensorTypeTrueDepth;
  } else if (type == AVCaptureDeviceTypeBuiltInWideAngleCamera) {
    return PigeonSensorTypeWideAngle;
  } else if (type == AVCaptureDeviceTypeBuiltInDualWideCamera) {
    return PigeonSensorTypeDualCamera;
  } else if (type == AVCaptureDeviceTypeBuiltInTripleCamera) {
    return PigeonSensorTypeTripleCamera;
  } else {
    return PigeonSensorTypeUnknown;
  }
}

+ (AVCaptureDeviceType)deviceTypeFromSensorType:(PigeonSensorType)sensorType {
  if (sensorType == PigeonSensorTypeTelephoto) {
    return AVCaptureDeviceTypeBuiltInTelephotoCamera;
  } else if (sensorType == PigeonSensorTypeUltraWideAngle) {
    return AVCaptureDeviceTypeBuiltInUltraWideCamera;
  } else if (sensorType == PigeonSensorTypeTrueDepth) {
    return AVCaptureDeviceTypeBuiltInTrueDepthCamera;
  } else if (sensorType == PigeonSensorTypeWideAngle) {
    return AVCaptureDeviceTypeBuiltInWideAngleCamera;
  } else if (sensorType == PigeonSensorTypeDualCamera) {
    return AVCaptureDeviceTypeBuiltInDualWideCamera;
  } else if (sensorType == PigeonSensorTypeTripleCamera) {
    return AVCaptureDeviceTypeBuiltInTripleCamera;
  } else {
    return AVCaptureDeviceTypeBuiltInWideAngleCamera;
  }
}

@end
