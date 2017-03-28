//
//  ViewController.h
//  WFCapture
//
//  Created by babywolf on 17/3/3.
//  Copyright © 2017年 babywolf. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum{
    WFShowModeNone,
    WFShowModeImage,
    WFShowModeMp4,
}WFShowMode;

@interface ViewController : UIViewController

@property (nonatomic, assign) WFShowMode showMode;

@end

