//
//  WFCaptureRecorder.h
//  WFCapture
//
//  Created by babywolf on 17/3/3.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

extern const NSString *const WFRecorderMovieURL;
extern const NSString *const WFRecorderMovieDuration;

typedef enum{
    WFCaptureRecorderFinishedReasonNormal,
    WFCaptureRecorderFinishedReasonCancel
}WFCaptureRecorderFinishedReason;

typedef void(^FinishRecordingBlock)(NSDictionary *info, WFCaptureRecorderFinishedReason reason);

typedef void(^FocusAreaDidChanged)();

typedef void(^AuthorizationResult)(BOOL success);

@interface WFCaptureRecorder : NSObject

@property (nonatomic, copy) FinishRecordingBlock finishBlock;
@property (nonatomic, copy) FocusAreaDidChanged focusAreaDidChangedBlock;
@property (nonatomic, copy) AuthorizationResult authorizationResultBlcok;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;

@property (nonatomic, strong) NSURL *recordURL;

@property (nonatomic, assign) CGSize cropSize;

@property (nonatomic, assign) NSTimeInterval duration;

+ (WFCaptureRecorder *)shareRecorder;

- (void)setup;
- (void)shutdown;
- (AVCaptureVideoPreviewLayer *)getPreviewLayer;
- (void)prepareCaptureWithBlock:(void (^)())block;
- (void)startCapture;
- (void)pauseCapture;
- (void)stopCapture;
- (void)finishCapture;
- (void)cancelCapture;
- (void)resumeCapture;

- (void)startSession;
- (BOOL)setScaleFoctor:(CGFloat)factor;
- (void)changeCamera;

- (void)changeFocusPoint:(CGPoint)point;

- (BOOL)isCapturing;
- (void)clearSession;

@end
