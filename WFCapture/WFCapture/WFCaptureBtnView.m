//
//  WFCaptureBtnView.m
//  WFCapture
//
//  Created by babywolf on 17/3/15.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import "WFCaptureBtnView.h"

#define kWFCaptureBtnWidth 70
#define kWFCaptureCommitBtnWidth 30

@implementation WFCaptureBtnView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _longPressView = [[UIView alloc] initWithFrame:CGRectMake((frame.size.width-kWFCaptureBtnWidth)/2.0, 0, kWFCaptureBtnWidth, kWFCaptureBtnWidth)];
        [_longPressView.layer setMasksToBounds:YES];
        _longPressView.layer.cornerRadius = kWFCaptureBtnWidth / 2.0;
        _longPressView.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.8];
        [self addSubview:_longPressView];
        
        _insideView = [[UIView alloc] initWithFrame:CGRectMake((kWFCaptureBtnWidth-50)/2.0, (kWFCaptureBtnWidth-50)/2.0, 50, 50)];
        _insideView.backgroundColor = [UIColor whiteColor];
        _insideView.layer.cornerRadius = 25;
        [_insideView.layer setMasksToBounds:YES];
        [_longPressView addSubview:_insideView];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [_longPressView addGestureRecognizer:tap];
        
        UILongPressGestureRecognizer *longpress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpressAction:)];
        [_longPressView addGestureRecognizer:longpress];
        
        _commitView = [[UIView alloc] initWithFrame:_longPressView.frame];
        [_commitView.layer setMasksToBounds:YES];
        _commitView.layer.cornerRadius = kWFCaptureBtnWidth / 2.0;
        _commitView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        _commitView.hidden = YES;
        [self addSubview:_commitView];
        UIImageView *commitImageView = [[UIImageView alloc] initWithFrame:CGRectMake((kWFCaptureBtnWidth-kWFCaptureCommitBtnWidth)/2.0, (kWFCaptureBtnWidth-kWFCaptureCommitBtnWidth)/2.0, kWFCaptureCommitBtnWidth, kWFCaptureCommitBtnWidth)];
        commitImageView.image = [UIImage imageNamed:@"video_save"];
        [_commitView addSubview:commitImageView];
        
        UITapGestureRecognizer *commitRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(commitAction)];
        [_commitView addGestureRecognizer:commitRecognizer];
        
        _cancelView = [[UIView alloc] initWithFrame:_longPressView.frame];
        [_cancelView.layer setMasksToBounds:YES];
        _cancelView.layer.cornerRadius = kWFCaptureBtnWidth/2.0;
        _cancelView.backgroundColor = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:0.8];
        _cancelView.hidden = YES;
        [self addSubview:_cancelView];
        UIImageView *cancelImageView = [[UIImageView alloc] initWithFrame:CGRectMake((kWFCaptureBtnWidth-kWFCaptureCommitBtnWidth)/2.0, (kWFCaptureBtnWidth-kWFCaptureCommitBtnWidth)/2.0, kWFCaptureCommitBtnWidth, kWFCaptureCommitBtnWidth)];
        cancelImageView.image = [UIImage imageNamed:@"video_back"];
        [_cancelView addSubview:cancelImageView];
        
        UITapGestureRecognizer *cancelRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelAction)];
        [_cancelView addGestureRecognizer:cancelRecognizer];
    }
    return self;
}

- (void)tapAction:(UIGestureRecognizer *)sender {
    
}

- (void)longpressAction:(UIGestureRecognizer *)sender {
    
}

- (void)commitAction {
    
}

- (void)cancelAction {
    
}

@end
