#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class NewRNCameraViewManager;

@interface NewRNCameraView : UIView

- (id)initWithManager:(NewRNCameraViewManager*)manager bridge:(RCTBridge *)bridge;

@end
