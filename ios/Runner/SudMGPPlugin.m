#import "SudMGPPlugin.h"

#import <Flutter/Flutter.h>
#import "QueueUtils.h"

#import <SudMGP/ISudFSMMG.h>
#import <SudMGP/ISudFSMStateHandle.h>
#import <SudMGP/ISudFSTAPP.h>
#import <SudMGP/SudMGP.h>

#import <UIKit/UIKit.h>

@interface SudMGPPlugin () <ISudFSMMG, FlutterStreamHandler>
@property(readonly, nonatomic) NSObject<FlutterBinaryMessenger> *messenger;
@property(readonly, nonatomic) FlutterMethodChannel *methodChannel;
@property(readonly, nonatomic) FlutterEventChannel *eventChannel;

@property(nonatomic, strong) FlutterEventSink eventSink;

@property(nonatomic, strong) id<ISudFSTAPP> gameApp;
@property(nonatomic, strong) NSString *viewSize;
@property(nonatomic, strong) NSString *gameConfig;
@property(nonatomic, strong) UIView *view;
@end

@implementation SudMGPPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  (void)[[SudMGPPlugin alloc] initWithRegistry:registrar];
}

- (instancetype)initWithRegistry:(NSObject<FlutterPluginRegistrar> *)registrar {
  self = [super init];

  NSAssert(self, @"super init cannot be nil");

  _messenger = [registrar messenger];

  _methodChannel = [FlutterMethodChannel methodChannelWithName:@"SudMGPPlugin"
                                               binaryMessenger:_messenger];

  _eventChannel = [FlutterEventChannel eventChannelWithName:@"SudMGPPluginEvent"
                                            binaryMessenger:_messenger];

  [_eventChannel setStreamHandler:self];

  [registrar addMethodCallDelegate:(NSObject<FlutterPlugin> *)self channel:_methodChannel];

  [registrar registerViewFactory:self withId:@"SudMGPPluginView"];

  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getVersion" isEqualToString:call.method]) {
    result(@{
      @"version" : [SudMGP getVersion],
      @"errorCode" : @0,
    });
  } else if ([@"initSDK" isEqualToString:call.method]) {
    NSString *appid = ((NSString *)call.arguments[@"appid"]);
    NSString *appkey = ((NSString *)call.arguments[@"appkey"]);
    BOOL isTestEnv = ((NSNumber *)call.arguments[@"isTestEnv"]).boolValue;
    [SudMGP setLogLevel:1];
    [SudMGP initSDK:appid
             appKey:appkey
          isTestEnv:isTestEnv
           listener:^(int errorCode, const NSString *message) {
             result(@{
               @"message" : message,
               @"errorCode" : [NSNumber numberWithInt:errorCode],
             });
           }];
  } else if ([@"getGameList" isEqualToString:call.method]) {
    [SudMGP getMGList:^(int errorCode, const NSString *_Nonnull message,
                        const NSString *_Nonnull dataJson) {
      result(@{
        @"errorCode" : [NSNumber numberWithInt:errorCode],
        @"dataJson" : dataJson,
        @"message" : message,
      });
    }];

  } else if ([@"loadGame" isEqualToString:call.method]) {
    NSString *userid = ((NSString *)call.arguments[@"userid"]);
    NSString *roomid = ((NSString *)call.arguments[@"roomid"]);
    NSString *code = ((NSString *)call.arguments[@"code"]);
    int64_t gameid = ((NSNumber *)call.arguments[@"gameid"]).longLongValue;
    NSString *language = ((NSString *)call.arguments[@"language"]);
    self.viewSize = ((NSString *)call.arguments[@"viewSize"]);
    self.gameConfig = ((NSString *)call.arguments[@"gameConfig"]);
    result(@{
      @"message" : @"success",
      @"errorCode" : @0,
    });
    self.gameApp = [SudMGP loadMG:userid
                           roomId:roomid
                             code:code
                             mgId:gameid
                         language:language
                            fsmMG:self
                         rootView:self.view];  // todo fix view

  } else if ([@"destroyGame" isEqualToString:call.method]) {
    [self.gameApp destroyMG];
    result(@{
      @"message" : @"success",
      @"errorCode" : @0,
    });
  } else if ([@"updateCode" isEqualToString:call.method]) {
    NSString *code = ((NSString *)call.arguments[@"code"]);
    [self.gameApp updateCode:code
                    listener:^(int errorCode, const NSString *_Nonnull message,
                               const NSString *_Nonnull dataJson) {
                      result(@{
                        @"errorCode" : [NSNumber numberWithInt:errorCode],
                        @"dataJson" : dataJson,
                        @"message" : message,
                      });
                    }];
    result(@{
      @"message" : @"success",
      @"errorCode" : @0,
    });
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)onExpireCode:(nonnull id<ISudFSMStateHandle>)handle dataJson:(nonnull NSString *)dataJson {
  FLTEnsureToRunOnMainQueue(^{
    self.eventSink(@{
      @"method" : @"onExpireCode",
      @"dataJson" : dataJson,
    });
  });
}

- (void)onGameDestroyed {
  FLTEnsureToRunOnMainQueue(^{
    self.eventSink(@{@"method" : @"onGameDestroyed"});
  });
}

- (void)onGameLog:(nonnull NSString *)dataJson {
  FLTEnsureToRunOnMainQueue(^{
    self.eventSink(@{
      @"method" : @"onGameLog",
      @"dataJson" : dataJson,
    });
  });
}

- (void)onGameStarted {
  FLTEnsureToRunOnMainQueue(^{
      self.eventSink(@{@"method" : @"onGameStarted"});
  });
}

- (void)onGameStateChange:(nonnull id<ISudFSMStateHandle>)handle
                    state:(nonnull NSString *)state
                 dataJson:(nonnull NSString *)dataJson {
  FLTEnsureToRunOnMainQueue(^{
    self.eventSink(@{
      @"method" : @"onGameStateChange",
      @"state" : state,
      @"dataJson" : dataJson,
    });
  });

  [handle success:@"{}"];
}

- (void)onGetGameCfg:(nonnull id<ISudFSMStateHandle>)handle dataJson:(nonnull NSString *)dataJson {
  [handle success:self.gameConfig];
}

- (void)onGetGameViewInfo:(nonnull id<ISudFSMStateHandle>)handle
                 dataJson:(nonnull NSString *)dataJson {
  FLTEnsureToRunOnMainQueue(^{
      
    self.eventSink(@{
      @"method" : @"onGetGameViewInfo",
      @"dataJson" : dataJson,
    });
  });
  [handle success:self.viewSize];
}

- (void)onPlayerStateChange:(nullable id<ISudFSMStateHandle>)handle
                     userId:(nonnull NSString *)userId
                      state:(nonnull NSString *)state
                   dataJson:(nonnull NSString *)dataJson {
  FLTEnsureToRunOnMainQueue(^{
    self.eventSink(@{
      @"method" : @"onPlayerStateChange",
      @"userId" : userId,
      @"state" : state,
      @"dataJson" : dataJson,
    });
  });
  [handle success:@"{}"];
}

- (void)onGameLoadingProgress:(int)stage retCode:(int)retCode progress:(int)progress {
    
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
    self.eventSink = nil;
    return nil;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
  self.eventSink = events;
  return nil;
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args {
  _view = [[UIView alloc] initWithFrame:frame];
  _view.backgroundColor = [UIColor blackColor];

  return self;
}
- (BOOL)destroyPlatformView:(NSNumber *)viewID {
  return YES;
}
- (nullable SudMGPPlugin *)getPlatformView:(NSNumber *)viewID {
  return self;
}
- (UIView *)getUIView {
  return _view;
}
- (UIView *)view {
  return _view;
}

@end
