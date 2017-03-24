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
    [self.delegate tapAction:sender];
    _longPressView.userInteractionEnabled = NO;
    [self performSelector:@selector(showCheckedView) withObject:nil afterDelay:0.3];
}

- (void)longpressAction:(UIGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            [UIView animateWithDuration:0.3 animations:^{
                _longPressView.transform = CGAffineTransformMakeScale(1.5, 1.5);
                _insideView.transform = CGAffineTransformMakeScale(0.7, 0.7);
            }completion:^(BOOL finished) {
                _duration = 0.f;
                _durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(computeDuration:) userInfo:nil repeats:YES];
                UIBezierPath *path = [UIBezierPath bezierPath];
                [path addArcWithCenter:CGPointMake(kWFCaptureBtnWidth/2.0, kWFCaptureBtnWidth/2.0) radius:kWFCaptureBtnWidth/2.0 startAngle:-M_PI/2.0 endAngle:M_PI/2.0*3 clockwise:YES];
                _arcLayer = [CAShapeLayer layer];
                _arcLayer.path = path.CGPath;
                _arcLayer.lineWidth = 5;
                _arcLayer.frame = CGRectMake(0, 0, kWFCaptureBtnWidth, kWFCaptureBtnWidth);
                _arcLayer.fillColor = [UIColor clearColor].CGColor;
                _arcLayer.strokeColor = [UIColor greenColor].CGColor;
                [_longPressView.layer addSublayer:_arcLayer];
                
                [self drawLineAAnimation:_arcLayer];
            }];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            
        }
            break;
        case UIGestureRecognizerStateEnded: {
            NSLog(@"animate end");
            _longPressView.userInteractionEnabled = NO;
            [_arcLayer removeAllAnimations];
            [_arcLayer removeFromSuperlayer];
            [_durationTimer invalidate];
            [UIView animateWithDuration:0.3 animations:^{
                _longPressView.transform = CGAffineTransformIdentity;
                _insideView.transform = CGAffineTransformIdentity;
            }completion:^(BOOL finished) {
                [self performSelector:@selector(showCheckedView) withObject:nil];
            }];
        }
            break;
        default:
            break;
    }
    [self.delegate longpressAction:sender];
}

- (void)commitAction {
    [self.delegate commitAction];
}

- (void)cancelAction {
    _longPressView.hidden = NO;
    _commitView.hidden = YES;
    _cancelView.hidden = YES;
    _commitView.transform = CGAffineTransformIdentity;
    _cancelView.transform = CGAffineTransformIdentity;
    [self.delegate cancelAction];
}

- (void)showCheckedView {
    if (_arcLayer) {
        [_arcLayer removeFromSuperlayer];
        [_arcLayer removeAllAnimations];
    }
    [_durationTimer invalidate];
    _longPressView.hidden = YES;
    _longPressView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.3 animations:^{
        _commitView.hidden = NO;
        _cancelView.hidden = NO;
        _commitView.transform = CGAffineTransformMakeTranslation(100, 0);
        _cancelView.transform = CGAffineTransformMakeTranslation(-100, 0);
    }completion:^(BOOL finished) {
        _longPressView.userInteractionEnabled = YES;
    }];
}

- (void)drawLineAAnimation:(CALayer *)layer {
    CABasicAnimation *bas = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    bas.duration = 12;
    bas.delegate = self;
    bas.fromValue = [NSNumber numberWithFloat:0];
    bas.toValue = [NSNumber numberWithFloat:1];
    [layer addAnimation:bas forKey:@"key"];
}

- (void)computeDuration:(NSTimer *)timer {
    _duration += 0.1;
    if (_duration >= 10.5) {
        [self.delegate beyondMaxTime];
        [_durationTimer invalidate];
        [_arcLayer removeAllAnimations];
        [_arcLayer removeFromSuperlayer];
        [UIView animateWithDuration:0.3 animations:^{
            _longPressView.transform = CGAffineTransformIdentity;
            _insideView.transform = CGAffineTransformIdentity;
        }];
        [self performSelector:@selector(showCheckedView) withObject:nil afterDelay:0.5];
    }
}

@end
