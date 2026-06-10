//
//  CameraPicture.m
//  camerawesome
//
//  Created by Dimitri Dessus on 24/07/2020.
//

#import "CameraPictureController.h"
#import "ExifContainer.h"
#import "NSData+Exif.h"

@implementation CameraPictureController {
  CameraPictureController *selfReference;
}

- (instancetype)initWithPath:(NSString *)path
                     orientation:(NSInteger)orientation
                  sensorPosition:(PigeonSensorPosition)sensorPosition
                 saveGPSLocation:(bool)saveGPSLocation
               mirrorFrontCamera:(bool)mirrorFrontCamera
                     aspectRatio:(AspectRatio)aspectRatio
                      completion:(nonnull void (^)(NSNumber * _Nullable, FlutterError * _Nullable))completion
                        callback:(OnPictureTaken)callback {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _path = path;
  _completion = completion;
  _orientation = orientation;
  _completionBlock = callback;
  _sensorPosition = sensorPosition;
  _saveGPSLocation = saveGPSLocation;
  _aspectRatioType = aspectRatio;
  _mirrorFrontCamera = mirrorFrontCamera;
  
  if (aspectRatio == Ratio4_3) {
    _aspectRatio = 4.0/3.0;
  } else if(aspectRatio == Ratio16_9) {
    _aspectRatio = 16.0/9.0;
  } else {
    _aspectRatio = 1;
  }
  
  selfReference = self;
  return self;
}

- (NSData *)writeMetadataIntoImageData:(NSData *)imageData metadata:(NSMutableDictionary *)metadata {
  // create an imagesourceref
  CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
  
  // this is the type of image (e.g., public.jpeg)
  CFStringRef UTI = CGImageSourceGetType(source);
  
  // create a new data object and write the new image into it
  NSMutableData *dest_data = [NSMutableData data];
  CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)dest_data, UTI, 1, NULL);
  if (!destination) {
    NSLog(@"Error: Could not create image destination");
  }
  // add the image contained in the image source to the destination, overidding the old metadata with our modified metadata
  CGImageDestinationAddImageFromSource(destination, source, 0, (__bridge CFDictionaryRef) metadata);
  BOOL success = NO;
  success = CGImageDestinationFinalize(destination);
  if (!success) {
    NSLog(@"Error: Could not create data from image destination");
  }
  CFRelease(destination);
  CFRelease(source);
  return dest_data;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
     resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
      bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings
                error:(NSError *)error {
#pragma clang diagnostic pop
  
  selfReference = nil;
  if (error) {
    _completion(nil, [FlutterError errorWithCode:@"CAPTURE ERROR" message:error.description details:@""]);
    return;
  }
  
  // Add exif data
  ExifContainer *container = [[ExifContainer alloc] init];
  [container addCreationDate:[NSDate date]];
  
  // Save GPS location only if provided
  if (_saveGPSLocation) {
    CLLocationManager *locationManager = [CLLocationManager new];
    CLLocation *location = [locationManager location];
    [container addLocation:location];
  }
  
  // we ignore this error because plugin can only be installed on iOS 11+
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer
                                                             previewPhotoSampleBuffer:previewPhotoSampleBuffer];
#pragma clang diagnostic pop
  
  UIImage *image = [UIImage imageWithCGImage:[UIImage imageWithData:data].CGImage
                                       scale:1.0
                                 orientation:[self getJpegOrientation]];

  // Use CGImage native dimensions (landscape sensor coords) for the aspect ratio check.
  // image.size is the portrait-logical size after UIImageOrientationRight is applied, so
  // image.size.width/height are swapped relative to the actual pixel data — using them
  // for the aspect-ratio comparison caused a square crop (3024×3024) instead of the
  // correct full-frame crop (4032×3024 → portrait 3024×4032 after rotation).
  CGImageRef cgImageRef = [image CGImage];
  float cgWidth  = (float)CGImageGetWidth(cgImageRef);
  float cgHeight = (float)CGImageGetHeight(cgImageRef);
  float cgAspect = cgWidth / cgHeight;

  UIImage *imageConverted = image;

  if (fabsf(cgAspect - _aspectRatio) > 0.001f) {
    float targetW = cgWidth, targetH = cgHeight;
    if (cgAspect > _aspectRatio) {
      targetW = cgHeight * _aspectRatio;
    } else {
      targetH = cgWidth / _aspectRatio;
    }
    float cropX = (cgWidth  - targetW) / 2.0f;
    float cropY = (cgHeight - targetH) / 2.0f;
    CGRect cropRect = CGRectMake(cropX, cropY, targetW, targetH);
    CGImageRef cropped = CGImageCreateWithImageInRect(cgImageRef, cropRect);
    imageConverted = [UIImage imageWithCGImage:cropped
                                         scale:0.0
                                   orientation:[self getJpegOrientation]];
    CGImageRelease(cropped);
  }

  image = [UIImage imageWithCGImage:[imageConverted CGImage] scale:0.0 orientation:[self getJpegOrientation]];

  NSData *imageWithExif = [UIImageJPEGRepresentation(image, 1.0) addExif:container];
  
  bool success = [imageWithExif writeToFile:_path atomically:YES];
  if (!success) {
    _completion(nil, [FlutterError errorWithCode:@"IOError" message:@"unable to write file" details:nil]);
    return;
  }
  _completionBlock();
  
}


- (UIImageOrientation)getJpegOrientation {
  switch (_orientation) {
    case UIDeviceOrientationPortrait:
      if (self.sensorPosition == PigeonSensorPositionFront && _mirrorFrontCamera) {
        return UIImageOrientationLeftMirrored;
      } else {
        return UIImageOrientationRight;
      }
    case UIDeviceOrientationLandscapeRight:
      return (self.sensorPosition == PigeonSensorPositionBack) ? UIImageOrientationUp : UIImageOrientationDown;
    case UIDeviceOrientationLandscapeLeft:
      return (self.sensorPosition == PigeonSensorPositionBack) ? UIImageOrientationDown : UIImageOrientationUp;
    default:
      return UIImageOrientationLeft;
  }
}

@end
