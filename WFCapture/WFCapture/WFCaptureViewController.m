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

@interface WFCaptureViewController ()

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
    
}

- (void)changeCamera {
    
}

- (void)changeFocusPoint:(UITapGestureRecognizer *)recognizer {
    
}

- (void)changeFocus:(CGPoint)point {
    
}

- (void)showAlertView {
    
}

- (void)setupRecorder {
    
}

- (void)willResignActive:(NSNotification *)notification {
    
}

@end
