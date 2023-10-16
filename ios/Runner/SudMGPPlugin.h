#import <Flutter/Flutter.h>
#import <Flutter/FlutterPlatformViews.h>
#import <UIKit/UIKit.h>


@interface SudMGPPlugin :  NSObject<FlutterPlugin, FlutterPlatformViewFactory, FlutterPlatformView>

- (BOOL)destroyPlatformView:(nonnull NSNumber *)viewID;

- (nullable SudMGPPlugin *)getPlatformView:(nonnull NSNumber *)viewID;

- (nullable UIView *)getUIView;

@end

