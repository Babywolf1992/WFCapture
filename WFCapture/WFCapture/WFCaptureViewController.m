//
//  WFCaptureViewController.m
//  WFCapture
//
//  Created by babywolf on 17/3/15.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#define kScreen_Width ([UIScreen mainScreen].bounds.size.width)
#define kScreen_Height ([UIScreen mainScreen].bounds.size.height)

#import "WFCaptureViewController.h"
#import "WFCaptureBtnView.h"
#import "WFCaptureRecorder.h"
#import "WFPlayer.h"

@interface WFCaptureViewController ()<WFCaptureBtnViewDelegate>

@property (nonatomic, strong) WFCaptureBtnView *btnView;

@property (nonatomic, strong) UIView *preview;

@property (nonatomic, strong) UILabel *alertLabel;

@property (nonatomic, strong) CALayer *processLayer;

@property (nonatomic, assign) BOOL scale;

@property (nonatomic, strong) WFCaptureRecorder *recorder;

@property (nonatomic, strong) UIButton *backBtn;
@property (nonatomic, strong) UIButton *cameraBtn;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

@end

@implementation WFCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [self setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showAlertView];
    [self setupRecorder];
    [_recorder startSession];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self changeFocus:CGPointMake(self.view.frame.size.width/2.0, self.view.frame.size.height/2.0)];
    });
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.recorder clearSession];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupUI {
    _preview = [[UIView alloc] initWithFrame:self.view.bounds];
    _preview.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_preview];
    _btnView = [[WFCaptureBtnView alloc] initWithFrame:CGRectMake(0, kScreen_Height-80-40, kScreen_Width, 80)];
    _btnView.delegate = self;
    [self.view addSubview:_btnView];
    
    _alertLabel = [[UILabel alloc] initWithFrame:CGRectMake((kScreen_Width-130)/2.0, CGRectGetMinY(_btnView.frame)-40, 130, 30)];
    _alertLabel.text = @"轻触拍照，按住摄像";
    _alertLabel.font = [UIFont systemFontOfSize:14];
    _alertLabel.textColor = [UIColor whiteColor];
    _alertLabel.textAlignment = NSTextAlignmentCenter;
    _alertLabel.alpha = 0;
    [self.view addSubview:_alertLabel];
    
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _backBtn.frame = CGRectMake(10, 25, 60, 40);
    [_backBtn setImage:[UIImage imageNamed:@"Safari Back"] forState:UIControlStateNormal];
    [_backBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 20)];
    [_backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_backBtn];
    
    _cameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _cameraBtn.frame = CGRectMake(kScreen_Width-70, 25, 70, 40);
    [_cameraBtn setImage:[UIImage imageNamed:@"change_camera"] forState:UIControlStateNormal];
    [_cameraBtn setImageEdgeInsets:UIEdgeInsetsMake(0, 20, 0, 10)];
    [_cameraBtn addTarget:self action:@selector(changeCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cameraBtn];
    
    if (!_tap) {
        _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeFocusPoint:)];
        [self.view addGestureRecognizer:_tap];
        _tap.enabled = NO;
    }
}

- (void)backAction {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)changeCamera {
    [self.recorder changeCamera];
}

- (void)changeFocusPoint:(UITapGestureRecognizer *)recognizer {
    _tap.enabled = NO;
    CGPoint point = [recognizer locationInView:self.view];
    [self changeFocus:point];
}

- (void)changeFocus:(CGPoint)point {
    UIColor *color = [UIColor colorWithRed:0 green:0.8 blue:0 alpha:1];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(point.x-60, point.y-60, 120, 120)];
    UIView *subView1 = [[UIView alloc] initWithFrame:CGRectMake(0, 60, 10, 1)];
    subView1.backgroundColor = color;
    [view addSubview:subView1];
    
    UIView *subView2 = [[UIView alloc] initWithFrame:CGRectMake(120-10, 60, 10, 1)];
    subView2.backgroundColor = color;
    [view addSubview:subView2];
    
    UIView *subView3 = [[UIView alloc] initWithFrame:CGRectMake(60, 0, 1, 10)];
    subView3.backgroundColor = color;
    [view addSubview:subView3];
    
    UIView *subView4 = [[UIView alloc] initWithFrame:CGRectMake(60, 120-10, 1, 10)];
    subView4.backgroundColor = color;
    [view addSubview:subView4];
    [self.view addSubview:view];
    float x = point.x / self.view.frame.size.width;
    float y = point.y / self.view.frame.size.height;
    view.layer.borderWidth = 0.7;
    view.backgroundColor = [UIColor clearColor];
    view.layer.borderColor = color.CGColor;
    [UIView animateKeyframesWithDuration:1 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.1 animations:^{
            view.transform = CGAffineTransformMakeScale(0.6, 0.6);
            view.layer.borderWidth = 10/6.0;
        }];
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
        _tap.enabled = YES;
    }];
    [_recorder changeFocusPoint:CGPointMake(x, y)];
}

- (void)showAlertView {
    [UIView animateKeyframesWithDuration:3 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1 animations:^{
            _alertLabel.alpha = 1;
        }];
        [UIView addKeyframeWithRelativeStartTime:1 relativeDuration:2 animations:^{
            _alertLabel.alpha = 0;
        }];
    } completion:nil];
}

- (void)longpressAction:(UIGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            [self.recorder startCapture];
        }
            break;
        case UIGestureRecognizerStateChanged: {
            
        }
            break;
        case UIGestureRecognizerStateEnded: {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.recorder finishCapture];
                [self.recorder pauseCapture];
            });
            NSLog(@"拍摄结束");
        }
            break;
        default:
            break;
    }
}

- (void)tapAction:(UIGestureRecognizer *)sender {
    [self.recorder startCapture];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recorder finishCapture];
        [self.recorder pauseCapture];
    });
}

- (void)commitAction {
    [self.recorder stopCapture];
}

- (void)cancelAction {
    [self.recorder cancelCapture];
    [self.recorder setup];
    
    [self.recorder startCapture];
}

- (void)beyondMaxTime {
    NSLog(@"beyondMaxTime");
    [self.recorder finishCapture];
    [self.recorder pauseCapture];
}

- (void)setupRecorder {
    _recorder = [WFCaptureRecorder shareRecorder];
    
    _recorder.cropSize = CGSizeMake(kScreen_Width, kScreen_Height);
    __weak WFCaptureViewController *blockSelf = self;
    [_recorder setAuthorizationResultBlcok:^(BOOL success){
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"没有权限"
                                                                message:nil
                                                               delegate:blockSelf
                                                      cancelButtonTitle:@"好的"
                                                      otherButtonTitles:nil];
                [alert show];
            });
        }
    }];
    
    [_recorder prepareCaptureWithBlock:^{
        AVCaptureVideoPreviewLayer *preview = [_recorder getPreviewLayer];
        preview.backgroundColor = [UIColor blackColor].CGColor;
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [preview removeFromSuperlayer];
        preview.frame = blockSelf.view.bounds;
        
        [blockSelf.preview.layer addSublayer:preview];
    }];
    
    [_recorder setFinishBlock:^(NSDictionary *info, WFCaptureRecorderFinishedReason reason){
        switch (reason) {
            case WFCaptureRecorderFinishedReasonNormal: {
                NSLog(@"%@",info);
                NSNumber *durationValue = [info objectForKey:WFRecorderMovieDuration];
                double duration = [durationValue doubleValue];
                if (duration <= 1) {
                    //拍照片
                    NSURL *fileurl = [info objectForKey:WFRecorderMovieURL];
                    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:fileurl options:nil];
                    AVAssetImageGenerator *assetImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
                    assetImageGenerator.appliesPreferredTrackTransform = YES;
                    assetImageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
                    
                    CGImageRef thumbnailImageRef = NULL;
                    NSError *thumbnailImageGenerationError = nil;
                    CMTime actualTime;
                    thumbnailImageRef = [assetImageGenerator copyCGImageAtTime:CMTimeMake(0.0, 600) actualTime:&actualTime error:&thumbnailImageGenerationError];
                    UIImage *thumbnailImage = [[UIImage alloc] initWithCGImage:thumbnailImageRef];
                    CGImageRelease(thumbnailImageRef);
                    if (!thumbnailImage) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"error" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [alert show];
                        [blockSelf.btnView cancelAction];
                    }else {
                        //截图成功
                    }
                }else {
                    //拍视频
                    NSLog(@"拍摄完成");
//                    wfplay
                }
            }
                break;
            case WFCaptureRecorderFinishedReasonCancel: {
                
            }
                break;
            default:
                break;
        }
    }];
}

- (void)willResignActive:(NSNotification *)notification {
    
}

@end
