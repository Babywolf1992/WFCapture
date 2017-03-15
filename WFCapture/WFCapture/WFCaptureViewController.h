//
//  WFCaptureViewController.h
//  WFCapture
//
//  Created by babywolf on 17/3/15.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
typedef enum {
    WFCaptureModeVideo = 0,
    WFCaptureModePicture = 1,
}WFCaptureMode;

@interface WFCaptureViewController : UIViewController

@property (nonatomic, weak) ViewController *controller;

@end
