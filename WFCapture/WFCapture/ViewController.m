//
//  ViewController.m
//  WFCapture
//
//  Created by babywolf on 17/3/3.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import "ViewController.h"
#import "WFCaptureViewController.h"
#import "WFPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.showMode = WFShowModeNone;
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2.0-50, self.view.frame.size.height/2.0-30, 100, 30)];
    [btn setTitle:@"拍摄" forState:UIControlStateNormal];
    [btn setTitle:@"拍摄" forState:UIControlStateHighlighted];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.showMode == WFShowModeImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        imageView.image = self.image;
        [self.view addSubview:imageView];
        self.showMode = WFShowModeNone;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:tap];
    }else if (self.showMode == WFShowModeMp4) {
        WFPlayer *player = [[WFPlayer alloc] init];
        self.showMode = WFShowModeNone;
        [self presentViewController:player animated:YES completion:nil];
    }
}

- (void)btnAction:(UIButton *)sender {
    WFCaptureViewController *controller = [[WFCaptureViewController alloc] init];
    controller.controller = self;   //传值用
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)tapAction:(UIGestureRecognizer *)render {
    [render.view removeFromSuperview];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
