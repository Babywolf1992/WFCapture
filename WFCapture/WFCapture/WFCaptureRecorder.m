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
#import <UIKit/UIKit.h>

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

static WFCaptureRecorder *recorder;
+ (WFCaptureRecorder *)shareRecorder {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorder = [[WFCaptureRecorder alloc] init];
    });
    return recorder;
}

- (instancetype)init {
    if (self = [super init]) {
        _duration = 0.f;
        _sessionQueuee = dispatch_queue_create("com.recorder.queue", DISPATCH_QUEUE_SERIAL);
        _videoDataOutputQueue = dispatch_queue_create("com.recorder.video", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }
    return self;
}

- (void)addObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:_session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:_session];
}

#pragma mark ---
- (void)setup {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    self.result = WFCaptureRecorderSetupResultSuccess;
                }
            }];
        }
            break;
        case AVAuthorizationStatusAuthorized: {
            
        }
            break;
        default: {
            self.result = WFCaptureRecorderSetupResultNotAuthorized;
        }
            break;
    }
    if (self.result != WFCaptureRecorderSetupResultSuccess) {
        if (self.authorizationResultBlcok) {
            self.authorizationResultBlcok(NO);
        }
        return;
    }
    if (_session == nil) {
        NSLog(@"starting up server");
        
        self.isCapturing = NO;
        _currentFile = 0;
        _discout = NO;
        
        self.session = [[AVCaptureSession alloc] init];
        self.result = WFCaptureRecorderSetupResultSuccess;
        
        dispatch_async(self.sessionQueuee, ^{
            _captureDevice = [WFCaptureRecorder deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
            
            NSError *error;
            _videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
            if (!_videoDeviceInput) {
                NSLog(@"未找到设备");
            }
            
            [_session beginConfiguration];
            
            if ([_session canAddInput:_videoDeviceInput]) {
                [_session addInput:_videoDeviceInput];
                [_session removeOutput:_videoDataOutput];
                
                _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
                _videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
                [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
                _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
                
                if ([_session canAddOutput:_videoDataOutput]) {
                    [_session addOutput:_videoDataOutput];
                    
                    [_captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:FocusAreaChangedContext];
                    
                    _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
                    
                    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                    if (statusBarOrientation != UIInterfaceOrientationUnknown) {
                        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                    }
                    _videoConnection.videoOrientation = initialVideoOrientation;
                }
            }else {
                NSLog(@"无法添加视频输入到session");
            }
            
            AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            AVCaptureInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
            if (!audioDeviceInput) {
                NSLog(@"不能创建audio设备");
            }
            if ([_session canAddInput:audioDeviceInput]) {
                [_session addInput:audioDeviceInput];
            }else {
                NSLog(@"不能添加audio设备到session");
            }
            
            AVCaptureAudioDataOutput *audioOutput = [[AVCaptureAudioDataOutput alloc] init];
            dispatch_queue_t audioCaptureQueue = dispatch_queue_create("com.recorder.audio", DISPATCH_QUEUE_SERIAL);
            [audioOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
            if ([self.session canAddOutput:audioOutput]) {
                [_session addOutput:audioOutput];
            }
            _audioConnection = [audioOutput connectionWithMediaType:AVMediaTypeAudio];
            [_session commitConfiguration];
            
            int frameRate;
            if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                [_session setSessionPreset:AVCaptureSessionPresetHigh];
            }
            frameRate = 30;
            
            CMTime frameDuration = CMTimeMake(1, frameRate);
            
            if ([_captureDevice lockForConfiguration:&error]) {
                _captureDevice.activeVideoMaxFrameDuration = frameDuration;
                _captureDevice.activeVideoMinFrameDuration = frameDuration;
                [_captureDevice unlockForConfiguration];
            }
        });
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    [self addObservers];
}

- (void)shutdown {
    
}

- (AVCaptureVideoPreviewLayer *)getPreviewLayer {
    return _preview;
}

- (void)startCapture {
    @synchronized (self) {
        dispatch_async(_sessionQueuee, ^{
            if (!self.isCapturing) {
                if (![_session isRunning]) {
                    [_session startRunning];
                }
                NSLog(@"starting capture");
                _writer = nil;
                _discout = NO;
                _timeOffset = CMTimeMake(0, 0);
                self.isCapturing = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(computeDuration:) userInfo:nil repeats:YES];
                });
                _duration = 0.f;
            }
        });
    }
}

- (void)pauseCapture {
    
}

- (void)stopCapture {
    [_session stopRunning];
    [self finishCaptureWithReason:WFCaptureRecorderFinishedReasonNormal];
}

- (void)finishCapture {
    [_session stopRunning];
}

- (void)cancelCapture {
    [self finishCaptureWithReason:WFCaptureRecorderFinishedReasonCancel];
}

- (void)prepareCaptureWithBlock:(void (^)())block {
    dispatch_async(_sessionQueuee, ^{
        [self setup];
        dispatch_sync(dispatch_get_main_queue(), ^{
            block();
        });
        if (!_session.isRunning) {
            [_session startRunning];
        }
    });
}

- (void)resumeCapture {
    @synchronized (self) {
        NSLog(@"resuming capture");
        dispatch_async(dispatch_get_main_queue(), ^{
            _durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(computeDuration:) userInfo:nil repeats:YES];
        });
    }
}

- (void)finishCaptureWithReason:(WFCaptureRecorderFinishedReason)reason {
    @synchronized (self) {
        if (self.isCapturing) {
            self.isCapturing = NO;
            [_durationTimer invalidate];
            dispatch_async(_sessionQueuee, ^{
                switch (reason) {
                    case WFCaptureRecorderFinishedReasonNormal: {
                        [_writer finishRecording];
                    }
                        break;
                    case WFCaptureRecorderFinishedReasonCancel: {
                        [_writer cancelRecording];
                    }
                        break;
                    default:
                        break;
                }
                self.finishedReason = reason;
            });
        }
    }
}

- (void)computeDuration:(NSTimer *)timer {
    if (self.isCapturing) {
        [self willChangeValueForKey:@"duration"];
        _duration += 0.1;
        [self didChangeValueForKey:@"duration"];
    }
}

#pragma mark ---
- (void)startSession {
    if (!_session.isRunning) {
        [_session startRunning];
    }
}

- (BOOL)setScaleFoctor:(CGFloat)factor {
    [_captureDevice lockForConfiguration:nil];
    BOOL success = NO;
    
    if (_captureDevice.activeFormat.videoMaxZoomFactor > factor) {
        [_captureDevice rampToVideoZoomFactor:factor withRate:30.f];
        NSLog(@"current format: %@, max zoom factor: %f",_captureDevice.activeFormat,_captureDevice.activeFormat.videoMaxZoomFactor);
        success = YES;
    }
    [_captureDevice unlockForConfiguration];
    return success;
}

- (void)changeCamera {
    dispatch_async(_sessionQueuee, ^{
        AVCaptureDevice *currentVideoDevice = self.videoDeviceInput.device;
        AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
        
        switch (currentPosition) {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront: {
                preferredPosition = AVCaptureDevicePositionBack;
            }
                break;
            case AVCaptureDevicePositionBack: {
                preferredPosition = AVCaptureDevicePositionFront;
            }
                break;
            default:
                break;
        }
        if (_captureDevice.position == AVCaptureDevicePositionBack) {
            [_captureDevice removeObserver:self forKeyPath:@"adjustingFocus"];
        }
        AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice error:nil];
        [_session beginConfiguration];
        [_session addInput:videoDeviceInput];
        if ([_session canAddInput:videoDeviceInput]) {
            [_session addInput:videoDeviceInput];
            
            if (_captureDevice.position != AVCaptureDevicePositionFront) {
                [_captureDevice lockForConfiguration:nil];
                [_captureDevice addObserver:self forKeyPath:@"adjustingFocus" options:NSKeyValueObservingOptionNew context:FocusAreaChangedContext];
                [_captureDevice unlockForConfiguration];
            }
            
            self.videoDeviceInput = videoDeviceInput;
        }else {
            [_session addInput:self.videoDeviceInput];
        }
        
        _videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        if (statusBarOrientation != UIInterfaceOrientationUnknown) {
            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
        _videoConnection.videoOrientation = initialVideoOrientation;
        
        [self.session commitConfiguration];
    });
}

#pragma mark ---
- (void)changeFocusPoint:(CGPoint)point {
    if ([_captureDevice isFocusPointOfInterestSupported]) {
        [_captureDevice lockForConfiguration:nil];
        [_captureDevice setFocusPointOfInterest:point];
        [_captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [_captureDevice unlockForConfiguration];
    }
}

#pragma mark ---
- (BOOL)isCapturing {
    return _isCapturing;
}

- (void)clearSession {
    [_session stopRunning];
    _session = nil;
}
                              
#pragma mark ---- Device Configration
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            captureDevice = device;
            break;
        }
    }
    return captureDevice;
}

#pragma mark ---- AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate method
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL bVideo = YES;
    
    @synchronized (self) {
        if (!self.isCapturing) {
            return;
        }
        if (connection != _videoConnection) {
            bVideo = NO;
        }
        if (_writer == nil && !bVideo) {
            _recordURL = [NSURL fileURLWithPath:[self getFilePath]];
            CGFloat width = _cropSize.width;
            CGFloat height = _cropSize.height;
            if ((int)width % 2 == 1) {
                width = _cropSize.width - 1;
            }
            if ((int)height % 2 == 1) {
                height = _cropSize.height - 1;
            }
            CGSize size = CGSizeMake(width, height);
            _writer = [[WFCaptureWriter alloc] initWithURL:_recordURL cropSize:size];
            _writer.delegate = self;
        }
        if (_discout) {
            if (bVideo) {
                return;
            }
            _discout = NO;
            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CMTime last = bVideo ? _lastvideo : _lastAudio;
            if (last.flags & kCMTimeFlags_Valid) {
                if (_timeOffset.flags & kCMTimeFlags_Valid) {
                    pts = CMTimeSubtract(pts, _timeOffset);
                }
                CMTime offset = CMTimeSubtract(pts, last);
                if (_timeOffset.value == 0) {
                    _timeOffset = offset;
                }else {
                    _timeOffset = CMTimeAdd(_timeOffset, offset);
                }
            }
            _lastvideo.flags = 0;
            _lastAudio.flags = 0;
        }
        CFRetain(sampleBuffer);
        if (_timeOffset.value > 0) {
            CFRelease(sampleBuffer);
            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
        }
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
        if (bVideo) {
            _lastvideo = pts;
            [_writer appendVideoBuffer:sampleBuffer];
        }else {
            _lastAudio = pts;
            [_writer appendAudioBuffer:sampleBuffer];
        }
    }
    CFRelease(sampleBuffer)
}

- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++) {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}

#pragma mark ----- WFCaptureWriterDelegate method
- (void)captureWriterDidFinishRecording:(WFCaptureWriter *)recorder status:(BOOL)isCancel {
    
}

#pragma mark ----- observer method
- (void)sessionWasInterrupted:(NSNotification *)notification {
    BOOL showResumeButton = NO;
    
    if (&AVCaptureSessionInterruptionReasonKey) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo [AVCaptureSessionInterruptionReasonKey] integerValue];
        if (reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient || reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient) {
            showResumeButton = YES;
        }else if (reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps) {
            
        }
    }else {
        showResumeButton = ([UIApplication sharedApplication].applicationState == UIApplicationStateInactive);
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification {
    if (!_session.isRunning) {
        [_session startRunning];
    }
}

- (NSString *)getFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"test.mp4"];
    return filePath;
}

@end
