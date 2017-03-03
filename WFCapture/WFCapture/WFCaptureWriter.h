//
//  WFCaptureWriter.h
//  WFCapture
//
//  Created by babywolf on 17/3/3.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class WFCaptureWriter;

@protocol WFCaptureWriterDelegate <NSObject>

- (void)captureWriterDidFinishRecording:(WFCaptureWriter *)recorder status:(BOOL)isCancel;

@end

@interface WFCaptureWriter : NSObject

@property (nonatomic, weak) id<WFCaptureWriterDelegate> delegate;

@property (nonatomic, strong) NSURL *recordingURL;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithURL:(NSURL *)URL cropSize:(CGSize)cropSize;

- (void)setCropSize:(CGSize)size;

- (void)prepareRecording;

- (void)finishRecording;
- (void)cancelRecording;

- (void)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer;

@end
