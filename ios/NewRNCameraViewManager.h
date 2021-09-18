#import <React/RCTViewManager.h>
#import <AVFoundation/AVFoundation.h>

@class NewRNCameraView;

@interface NewRNCameraViewManager : RCTViewManager <AVCapturePhotoCaptureDelegate>

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCapturePhotoOutput *photoOutput;
@property (nonatomic, assign) NSInteger cameraFace;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NewRNCameraView *camera;


- (void)initializeCaptureSessionInput;
- (void)startSession;
- (void)stopSession;
- (void)focusAndExposeAtPoint:(CGPoint)point;
- (void)pinchToZoom:(CGFloat)velocity;


@end
