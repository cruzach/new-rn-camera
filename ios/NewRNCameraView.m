#import <React/RCTBridge.h>

#import "NewRNCameraView.h"
#import "NewRNCameraViewManager.h"

@interface NewRNCameraView ()

@property (nonatomic, weak) NewRNCameraViewManager *manager;
@property (nonatomic, weak) RCTBridge *bridge;

@end

@implementation NewRNCameraView

- (id)initWithManager:(NewRNCameraViewManager*)manager bridge:(RCTBridge *)bridge
{
  
  if ((self = [super init])) {
    self.manager = manager;
    self.bridge = bridge;
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchToZoomRecognizer:)];
    [self addGestureRecognizer:pinchGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapToFocusAndExpose:)];
    [self addGestureRecognizer:tapGesture];
    
    [self.manager initializeCaptureSessionInput];
    [self.manager startSession];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  self.manager.previewLayer.frame = self.bounds;
  [self setBackgroundColor:[UIColor blackColor]];
  [self.layer insertSublayer:self.manager.previewLayer atIndex:0];
}

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
  [super insertReactSubview:view atIndex:atIndex];
  [self insertSubview:view atIndex:atIndex + 1];
  return;
}

- (void)removeReactSubview:(UIView *)subview
{
  [super removeReactSubview:subview];
  [subview removeFromSuperview];
  return;
}

- (void)removeFromSuperview
{
  [super removeFromSuperview];
  [self.manager stopSession];
}

-(void) handleTapToFocusAndExpose:(UITapGestureRecognizer*)tapRecognizer {
  [self.manager focusAndExposeAtPoint:[tapRecognizer locationInView:self]];
}

-(void) handlePinchToZoomRecognizer:(UIPinchGestureRecognizer*)pinchRecognizer {
  if (pinchRecognizer.state == UIGestureRecognizerStateChanged) {
    [self.manager pinchToZoom:pinchRecognizer.velocity];
  }
}

@end
