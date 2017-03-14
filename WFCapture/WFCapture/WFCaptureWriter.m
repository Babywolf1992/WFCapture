//
//  WFCaptureWriter.m
//  WFCapture
//
//  Created by babywolf on 17/3/3.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import "WFCaptureWriter.h"
#import <UIKit/UIKit.h>

//#define kScreenWidth 

@interface WFCaptureWriter ()

@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) AVAssetWriter *videoWriter;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;
@property (nonatomic, assign) CMSampleBufferRef currentBuffer;
@property (nonatomic, assign) CGSize cropSize;

@end

@implementation WFCaptureWriter

- (instancetype)initWithURL:(NSURL *)URL {
    if (self = [super init]) {
        _recordingURL = URL;
        
        [self prepareRecording];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL cropSize:(CGSize)cropSize {
    if (self = [super init]) {
        _recordingURL = URL;
        if (cropSize.width == 0 || cropSize.height == 0) {
            _cropSize = [UIScreen mainScreen].bounds.size;
        }else {
            _cropSize = cropSize;
        }
    }
    return self;
}

- (void)setCropSize:(CGSize)size {
    _cropSize = size;
}

- (void)prepareRecording {
    NSString *filePath = [[self.videoWriter.outputURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
        if ([[NSFileManager defaultManager] removeItemAtURL:self.videoWriter.outputURL error:nil]) {
            NSLog(@"remove Item");
        }
    }
    
    NSString *betaCompressionDirectory = [[_recordingURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    NSError *error = nil;
    unlink([betaCompressionDirectory UTF8String]);
    
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory] fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(self.videoWriter);
    
    if (error) {
        NSLog(@"error = %@",[error localizedDescription]);
        
        NSDictionary *videoSettings;
        
        if (_cropSize.height == 0 || _cropSize == 0) {
            _cropSize = [UIScreen mainScreen].bounds.size;
        }
        
        videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                         AVVideoCodecH264, AVVideoCodecKey,
                         [NSNumber numberWithInt:_cropSize.width*[UIScreen mainScreen].scale],AVVideoWidthKey,
                          [NSNumber numberWithInt:_cropSize.height*[UIScreen mainScreen].scale],
                          AVVideoHeightKey,
                         AVVideoScalingModeResizeAspectFill, AVVideoScalingModeKey, nil];
        
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
        NSParameterAssert(self.videoInput);
        self.videoInput.expectsMediaDataInRealTime = YES;
        
        NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey, nil];
        
        self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
        
        NSParameterAssert(self.videoInput);
        
        NSParameterAssert([self.videoWriter canAddInput:self.videoInput]);
        
        AudioChannelLayout acl;
        
        bzero(&acl, sizeof(acl));
        
        acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        
        NSDictionary *audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,
                                             [NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                                             [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                             [NSNumber numberWithInt:1], AVNumberOfChannelsKey,
                                             [NSData dataWithBytes:&acl length:sizeof(acl)], AVChannelLayoutKey,nil];
        
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
        self.audioInput.expectsMediaDataInRealTime = YES;
        
        [self.videoWriter addInput:self.audioInput];
        [self.videoWriter addInput:self.videoInput];
        
        switch (self.videoWriter.status) {
            case AVAssetWriterStatusUnknown: {
                [self.videoWriter startWriting];
            }
                break;
                
            default:
                break;
        }
    }
}

- (void)finishRecording {
    [self finishRecordingIsCancel:NO];
}

- (void)cancelRecording {
    [self finishRecordingIsCancel:YES];
}

- (void)finishRecordingIsCancel:(BOOL)isCancel {
    [self.videoInput markAsFinished];
    
    [self.videoWriter finishWritingWithCompletionHandler:^{
        NSLog(@"writer end");
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(captureWriterDidFinishRecording:status:)]) {
                [self.delegate captureWriterDidFinishRecording:self status:isCancel];
            }
        });
    }];
}

- (void)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    if (self.videoWriter.status != AVAssetExportSessionStatusUnknown) {
        [self.videoWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        _currentBuffer = sampleBuffer;
        if (self.audioInput.readyForMoreMediaData) {
            [self.audioInput appendSampleBuffer:sampleBuffer];
        }else {
            NSLog(@"appendAudioBuffer error");
        }
    }
}

- (void)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer {
    if (self.videoWriter.status != AVAssetExportSessionStatusUnknown) {
        [self.videoWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        _currentBuffer = sampleBuffer;
        [self.videoInput appendSampleBuffer:sampleBuffer];
    }else {
        NSLog(@"appendVideoBuffer error");
    }
}

@end
