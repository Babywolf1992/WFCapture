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
                
                if ([_session canAddOutput:_videoDataOutput];) {
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
    
}

#pragma mark ----- WFCaptureWriterDelegate method
- (void)captureWriterDidFinishRecording:(WFCaptureWriter *)recorder status:(BOOL)isCancel {
    
}

#pragma mark ----- observer method
- (void)sessionWasInterrupted:(NSNotification *)notification {
    
}

- (void)sessionInterruptionEnded:(NSNotification *)notification {
    
}

@end
