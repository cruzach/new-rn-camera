#import "NewRNCameraViewManager.h"
#import "NewRNCameraView.h"

#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@interface NewRNCameraViewManager ()

@property (nonatomic, strong) RCTPromiseResolveBlock resolveCapturedImage;
@property (nonatomic, strong) RCTPromiseRejectBlock rejectCapturedImage;

@end

@implementation NewRNCameraViewManager

RCT_EXPORT_MODULE();

- (UIView *)viewWithProps:(__unused NSDictionary *)props
{
  return [self view];
}

- (UIView *)view
{
  
  self.session = [AVCaptureSession new];
  self.previewLayer = [[AVCaptureVideoPreviewLayer  alloc] initWithSession:self.session];
  self.previewLayer.needsDisplayOnBoundsChange = YES;
  self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
  
  if(!self.camera){
    self.camera = [[NewRNCameraView alloc] initWithManager:self bridge:self.bridge];
  }
  return self.camera;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

- (id)init {
  if ((self = [super init])) {
    self.sessionQueue = dispatch_queue_create("NewRNCameraViewManagerQueue", DISPATCH_QUEUE_SERIAL);
    self.cameraFace = AVCaptureDevicePositionBack;
  }
  return self;
}

#pragma mark - Begin: custom view properties

RCT_CUSTOM_VIEW_PROPERTY(torch, NSString, NewRNCameraView) {
  dispatch_async(self.sessionQueue, ^{
    NSString *torchMode = [RCTConvert NSString:json];
    AVCaptureDevice *device = [self.captureDeviceInput device];
    NSError *error = nil;
    
    if (![device hasTorch]) return;
    if (![device lockForConfiguration:&error]) {
      NSLog(@"NewRNCameraViewManager encountered an error setting the torch mode: %@", error);
      return;
    }
    [device setTorchMode: [self getTorchModeFromString:torchMode]];
    [device unlockForConfiguration];
  });
}

- (AVCaptureTorchMode) getTorchModeFromString:(NSString *) string
{
  if ([string isEqualToString:@"on"]) {
    return AVCaptureTorchModeOn;
  }
  return AVCaptureTorchModeOff;
}

RCT_CUSTOM_VIEW_PROPERTY(zoom, CGFloat, NewRNCameraView) {
  dispatch_async(self.sessionQueue, ^{
    CGFloat value = [RCTConvert CGFloat:json];
    if (isnan(value)) {
      return;
    }
    NSError *error = nil;
    AVCaptureDevice *device = [self.captureDeviceInput device];
    
    if (!device) return;
    if (![device lockForConfiguration:&error]) {
      NSLog(@"NewRNCameraViewManager encountered an error setting the zoom: %@", error);
      return;
    }
    
    device.videoZoomFactor = [self getZoomFactorFromFloat:(CGFloat) MIN(1.0f, value)];
    [device unlockForConfiguration];
  });
}

RCT_CUSTOM_VIEW_PROPERTY(cameraFacing, NSString, NewRNCameraView) {
  NSString *cameraFaceString = [RCTConvert NSString:json];
  NSInteger newCameraFace = [self getCameraFaceFromString: cameraFaceString];
  if (self.cameraFace != newCameraFace){
    self.cameraFace = newCameraFace;
    [self initializeCaptureSessionInput];
    if (!self.session.isRunning) {
      [self startSession];
    }
  }
}

- (NSInteger)getCameraFaceFromString: (NSString*) string
{
  if ([string isEqualToString:@"front"]) {
    return AVCaptureDevicePositionFront;
  }
  return AVCaptureDevicePositionBack;
}

- (CGFloat)getZoomFactorFromFloat:(CGFloat) value
{
  CGFloat max = [self.captureDeviceInput device].activeFormat.videoMaxZoomFactor;
  const CGFloat min = 1;
  const CGFloat scaleDownMaxZoom = 0.020f; // Need to limit the max zoom to a reasonable number, roughly calibrated
  
  // TODO: Add multi-camera zoom out support
  //  if (@available(iOS 11.0, *)) {
  //    min = [self.captureDeviceInput device].minAvailableVideoZoomFactor;
  //  }
  return value * (max * scaleDownMaxZoom - min) + min;
}

#pragma mark - End: custom view properties

#pragma mark - Begin: native module methods

RCT_EXPORT_METHOD(requestCameraPermissions:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                           completionHandler:^(BOOL granted) {
    resolve(granted ? @"YES" : @"NO");
  }];
}

RCT_EXPORT_METHOD(requestStoragePermissions:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  if (@available(iOS 14, *)) {
    [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly
                                               handler:^(PHAuthorizationStatus status){
      resolve(status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited ? @"YES" : @"NO");
    }];
  } else {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
      resolve(status == PHAuthorizationStatusAuthorized  ? @"YES" : @"NO");
    }];
  }
}

RCT_EXPORT_METHOD(capture:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  _resolveCapturedImage = resolve;
  _rejectCapturedImage = reject;
  AVCapturePhotoSettings *outputSettings = AVCapturePhotoSettings.photoSettings;
  outputSettings.highResolutionPhotoEnabled = YES;
  [_photoOutput capturePhotoWithSettings:outputSettings delegate:self];
}

#pragma mark - End: native module methods

#pragma mark - Begin: AVCapturePhotoCaptureDelegate

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error API_AVAILABLE(ios(11.0))
{
  RCTPromiseRejectBlock reject = _rejectCapturedImage;
  RCTPromiseResolveBlock resolve = _resolveCapturedImage;
  _rejectCapturedImage = nil;
  _resolveCapturedImage = nil;
  if (error) {
    reject(@"NewRNCamera: Unable to save image output. ", error.description, nil);
  }
  [self saveToCameraRoll:[photo fileDataRepresentation] andResolve:resolve orReject:reject];
}

// Necessary for iOS 10
- (void)captureOutput:(AVCapturePhotoOutput *)output
didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer
previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer
     resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
      bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings
                error:(NSError *)error
{
  RCTPromiseRejectBlock reject = _rejectCapturedImage;
  RCTPromiseResolveBlock resolve = _resolveCapturedImage;
  _rejectCapturedImage = nil;
  _resolveCapturedImage = nil;
  if (error) {
    reject(@"NewRNCamera: Unable to save image output. ", error.description, nil);
  }
  
  // TODO: Test on iOS 10
  NSData *imageData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
  [self saveToCameraRoll:imageData andResolve:resolve orReject:reject];
}

- (void)saveToCameraRoll:(NSData *)imageData andResolve:(RCTPromiseResolveBlock)resolve orReject:(RCTPromiseRejectBlock)reject
{
  if (PHPhotoLibrary.authorizationStatus != PHAuthorizationStatusAuthorized) {
    reject(@"NewRNCamera", @"Unable to save photo to library. User must first grant permission.", nil);
  }
  
  __block PHObjectPlaceholder *placeholder;
  UIImage *takenImage = [UIImage imageWithData:imageData];
  [PHPhotoLibrary.sharedPhotoLibrary performChanges:^{
    PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:takenImage];
    placeholder = [changeRequest placeholderForCreatedAsset];
  } completionHandler:^(BOOL success, NSError * _Nullable error){
    if (success) {
      NSString *uri = [NSString stringWithFormat:@"ph://%@", [placeholder localIdentifier]];
      resolve(@{@"uri": uri, @"width": @(takenImage.size.width), @"height": @(takenImage.size.height)});
    } else {
      reject(@"NewRNCamera", error.description, nil);
    }
  }];
}

#pragma mark - End: AVCapturePhotoCaptureDelegate

#pragma mark - Begin: core functionality used in NewRNCamera.m

- (void)initializeCaptureSessionInput
{
  dispatch_async(self.sessionQueue, ^{
    [self.session beginConfiguration];
    
    NSError *error = nil;
    AVCaptureDevice *currentCaptureDevice = [self.captureDeviceInput device];
    AVCaptureDevice *captureDevice = [self getCaptureDeviceFacing: self.cameraFace];
    
    if (captureDevice == nil) {
      return;
    }
    
    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice  error:&error];
    
    if (error || captureDeviceInput == nil) {
      NSLog(@"NewRNCamera: unable to initialize. %@", error);
      return;
    }
    
    [self.session removeInput:self.captureDeviceInput];
    
    if ([self.session canAddInput:captureDeviceInput]) {
      [self.session addInput:captureDeviceInput];
      
      [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentCaptureDevice];
      [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(autoFocusOnCenterOfView:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
      
      self.captureDeviceInput = captureDeviceInput;
      
    }
    
    [self.session commitConfiguration];
  });
}

- (AVCaptureDevice *)getCaptureDeviceFacing:(AVCaptureDevicePosition)position
{
  AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera]
                                        mediaType:AVMediaTypeVideo
                                         position:position];
  
  NSArray *compatibleDevices = [captureDeviceDiscoverySession devices];
  return [compatibleDevices firstObject];
}

- (void)startSession {
  dispatch_async(self.sessionQueue, ^{
    AVCapturePhotoOutput *photoOutput = [AVCapturePhotoOutput new];
    photoOutput.highResolutionCaptureEnabled = YES;
    photoOutput.livePhotoCaptureEnabled = NO;
    
    if ([self.session canAddOutput:photoOutput])
    {
      [self.session beginConfiguration];
      self.session.sessionPreset = AVCaptureSessionPresetPhoto;
      [self.session addOutput:photoOutput];
      self.previewLayer.session = self.session;
      [self.session commitConfiguration];
      self.photoOutput = photoOutput;
    }
    
    [self.session startRunning];
  });
}

- (void)stopSession {
  dispatch_async(self.sessionQueue, ^{
    self.camera = nil;
    [self.previewLayer removeFromSuperlayer];
    [self.session commitConfiguration];
    [self.session stopRunning];
    for(AVCaptureInput *input in self.session.inputs) {
      [self.session removeInput:input];
    }
    for(AVCaptureOutput *output in self.session.outputs) {
      [self.session removeOutput:output];
    }
  });
}

- (void)autoFocusOnCenterOfView:(NSNotification *)notification
{
  CGPoint point = CGPointMake(.5, .5);
  [self focusAndExposeAtPoint:point];
}

- (void)focusAndExposeAtPoint:(CGPoint)point
{
  CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)self.previewLayer captureDevicePointOfInterestForPoint:point];
  dispatch_async([self sessionQueue], ^{
    AVCaptureDevice *device = [[self captureDeviceInput] device];
    NSError *error = nil;
    if (![device lockForConfiguration:&error]) {
      NSLog(@"NewRNCameraViewManager encountered an error focusing: %@", error);
      return;
    }
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
      [device setFocusMode:AVCaptureFocusModeAutoFocus];
      [device setFocusPointOfInterest:devicePoint];
    }
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeAutoExpose])
    {
      [device setExposureMode:AVCaptureExposureModeAutoExpose];
      [device setExposurePointOfInterest:devicePoint];
    }
    [device setSubjectAreaChangeMonitoringEnabled:YES];
    [device unlockForConfiguration];
  });
}

- (void)pinchToZoom:(CGFloat)velocity
{
  if (isnan(velocity)) {
    return;
  }
  const CGFloat scaleDownVelocity = 0.025f; // Roughly calibrated
  NSError *error = nil;
  AVCaptureDevice *device = [[self captureDeviceInput] device];
  if (![device lockForConfiguration:&error]) {
    NSLog(@"NewRNCameraViewManager encountered an error setting the zoom via a pinch: %@", error);
    return;
  }
  CGFloat zoomValue = device.videoZoomFactor + atan(velocity * scaleDownVelocity);
  device.videoZoomFactor = MAX(1.0f, MIN(device.activeFormat.videoMaxZoomFactor, zoomValue));
  [device unlockForConfiguration];
}

#pragma mark - End: core functionality used in NewRNCameraView.m

@end
