//
//  WFCaptureRecorder.m
//  WFCapture
//
//  Created by babywolf on 17/3/3.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import "WFCaptureRecorder.h"
#import "WFCaptureWriter.h"
#import <AssetsLibrary/AssetsLibrary.h>

static void *SessionRunningContext = &SessionRunningContext;
static void *CaptureStillImageContext = &CaptureStillImageContext;
static void *FocusAreaChangedContext = &FocusAreaChangedContext;

typedef enum{
    WFCaptureRecorderSetupResultSuccess,
    WFCaptureRecorderSetupResultNotAuthorized,
    WFCaptureRecorderSetupResultConfigurationFailed
}WFCaptureRecorderSetupResult;

@interface WFCaptureRecorder()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,WFCaptureWriterDelegate>
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t sessionQueuee;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;

@property (nonatomic, assign) WFCaptureRecorderFinishedReason finishedReason;
@property (nonatomic, assign) WFCaptureRecorderSetupResult result;
@property (nonatomic, strong) NSTimer *durationTimer;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;
@property (nonatomic, strong) WFCaptureWriter *writer;

@property (nonatomic, assign) BOOL isCapturing;
@property (nonatomic, assign) BOOL discout;
@property (nonatomic, assign) int currentFile;
@property (nonatomic, assign) CMTime timeOffset;
@property (nonatomic, assign) CMTime lastvideo;
@property (nonatomic, assign) CMTime lastAudio;

@property (nonatomic, assign) NSString *fileName;

@end

@implementation WFCaptureRecorder

+ (WFCaptureRecorder *)shareRecorder {
    
}

#pragma mark ---
- (void)setup {
    
}

- (void)shutdown {
    
}

- (AVCaptureVideoPreviewLayer *)getPreviewLayer {
    
}

- (void)startCapture {
    
}

- (void)pauseCapture {
    
}

- (void)stopCapture {
    
}

- (void)finishCapture {
    
}

- (void)cancelCapture {
    
}

- (void)resumeCapture {
    
}

#pragma mark ---
- (void)startSession {
    
}

- (BOOL)setScaleFoctor:(CGFloat)factor {
    
}

- (void)changeCamera {
    
}

#pragma mark ---
- (void)changeFocusPoint:(CGPoint)point {
    
}

#pragma mark ---
- (BOOL)isCapturing {
    
}

- (void)clearSession {
    
}

#pragma mark ---- AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate method
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

#pragma mark ----- WFCaptureWriterDelegate method
- (void)captureWriterDidFinishRecording:(WFCaptureWriter *)recorder status:(BOOL)isCancel {
    
}

@end
