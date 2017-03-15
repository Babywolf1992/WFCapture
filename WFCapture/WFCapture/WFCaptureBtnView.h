//
//  WFCaptureBtnView.h
//  WFCapture
//
//  Created by babywolf on 17/3/15.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WFCaptureBtnViewDelegate <NSObject>

@required
- (void)tapAction:(UIGestureRecognizer *)sender;
- (void)longpressAction:(UIGestureRecognizer *)sender;

- (void)commitAction;
- (void)cancelAction;
- (void)beyondMaxTime;

@end

@interface WFCaptureBtnView : UIView<CAAnimationDelegate>

@property (nonatomic, strong) NSTimer *durationTimer;
@property (nonatomic, assign) float duration;

@property (nonatomic, strong) UIView *longPressView;
@property (nonatomic, strong) UIView *insideView;
@property (nonatomic, strong) UIView *commitView;
@property (nonatomic, strong) UIView *cancelView;

@property (nonatomic, strong) CAShapeLayer *arcLayer;

@property (nonatomic, weak) id<WFCaptureBtnViewDelegate> delegate;

- (void)cancelAction;

@end
