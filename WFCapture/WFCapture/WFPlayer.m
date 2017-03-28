//
//  WFPlayer.m
//  WFPlayer
//
//  Created by babywolf on 16/12/27.
//  Copyright © 2016年 babywolf. All rights reserved.
//

#import "WFPlayer.h"
#import "ASIHTTPRequest.h"
#import "Reachability.h"
#import "WFDownloadCache.h"

@implementation WFPlayer
#pragma mark - life cycle method
- (instancetype)initWithURL:(NSString *)urlString {
    if (self = [super init]) {
        _request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:urlString]];
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.view.userInteractionEnabled = YES;
    [self createUI];
    [self willShowPlayer];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_request clearDelegatesAndCancel];
    [self removeVideoKVO];
    [self removeVideoTimerObserver];
    [self removeNotification];
}

#pragma mark - private method
- (void)createUI {
    _progresshud = [[MBProgressHUD alloc] initWithView:self.view];
    _progresshud.mode = MBProgressHUDModeDeterminate;
    _progresshud.progress = 0.0f;
    [self.view addSubview:_progresshud];
    
    //  backView
    _backView = [[UIView alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    _backView.backgroundColor = [UIColor clearColor];
    _backView.userInteractionEnabled = YES;
    [self.view addSubview:_backView];
    
    //  PlayButton
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    [_playButton setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateSelected];
    _playButton.frame = CGRectMake(15, HEIGHT-46-20, 46, 46);
    [_backView addSubview:_playButton];
    
    //  startTime
    _startTime = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_playButton.frame)+10, CGRectGetMidY(self.playButton.frame)-15/2.0, 35, 15)];
    _startTime.text = @"00:00";
    _startTime.font = [UIFont systemFontOfSize:12];
    //    self.startTime.backgroundColor = [UIColor redColor];
    _startTime.textColor = [UIColor whiteColor];
    [_backView addSubview:_startTime];
    
    //slider
    _progressSlider =[[UISlider alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_startTime.frame)+5, CGRectGetMinY(_startTime.frame), WIDTH-CGRectGetMaxX(_startTime.frame)-35-20, 15)];
    //  滑块左侧颜色
    _progressSlider.minimumTrackTintColor = [UIColor whiteColor];
    //  滑块右侧颜色
    _progressSlider.maximumTrackTintColor = [UIColor whiteColor];
    UIImage *thumbImage0 = [UIImage imageNamed:@"Oval 1"];
    [_progressSlider setThumbImage:thumbImage0 forState:UIControlStateNormal];
    [_progressSlider setThumbImage:thumbImage0 forState:UIControlStateSelected];
    [_progressSlider addTarget:self action:@selector(valueChange:other:) forControlEvents:UIControlEventValueChanged];
    [_progressSlider addTarget:self action:@selector(changeValueBegin:) forControlEvents:UIControlEventTouchDown];
    [_progressSlider addTarget:self action:@selector(changeVauleCancel:) forControlEvents:UIControlEventTouchUpInside];
    [_progressSlider addTarget:self action:@selector(changeVauleCancel:) forControlEvents:UIControlEventTouchUpOutside];
    //    _progressSlider.userInteractionEnabled = NO;
    [_backView addSubview:_progressSlider];
    
    //  endTime
    _endTime = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(_progressSlider.frame)+5, CGRectGetMinY(_progressSlider.frame), 35, 15)];
    self.endTime.text = @"00:00";
    self.endTime.font = [UIFont systemFontOfSize:12];
    self.endTime.textColor = [UIColor whiteColor];
    [_backView addSubview:self.endTime];
    
    //  backButton
    _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _backButton.frame = CGRectMake(10, 25, 60, 34);
    [_backButton setImage:[UIImage imageNamed:@"Safari Back"] forState:UIControlStateNormal];
    [_backButton setImageEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 20)];
    [_backButton addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    
    [_backView addSubview:_backButton];
    _playButton.selected = YES;
    _playButton.userInteractionEnabled = NO;
}

- (void)willShowPlayer {
    NSString *urlString = _request.url.absoluteString;
    NSString *filePath = [[WFDownloadCache shareDownloadCache] queryFile:urlString];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (filePath && [fileManager fileExistsAtPath:filePath]) {
        [self showPlayer:[NSURL fileURLWithPath:filePath]];
    }else {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == ReachableViaWWAN) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Hints", nil) message:NSLocalizedString(@"Are using flow, whether to continue to download", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"YES", nil),NSLocalizedString(@"Cancel", nil), nil];
            [alert show];
        }else {
            [self downloadFile];
        }
    }
}

- (void)showPlayer:(NSURL *)url {
    _playButton.userInteractionEnabled = YES;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
    [self.view addGestureRecognizer:tap];
    
    _item = [[AVPlayerItem alloc] initWithURL:url];
    _player = [AVPlayer playerWithPlayerItem:_item];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.frame = self.view.bounds;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer insertSublayer:_playerLayer atIndex:1];
    
    [self addVideoKVO];
    [self addVideoTimerObserver];
    [self addNotification];
}

#pragma mark - action method
-(void)tapAction {
    _backView.hidden = !_backView.hidden;
}

- (void)playAction:(UIButton *)sender {
    if (self.playButton.selected) {
        if (_progressSlider.value == 1) {
            _progressSlider.value = 0;
            [_player seekToTime:kCMTimeZero];
        }
        [_player play];
    }else {
        [_player pause];
    }
    self.playButton.selected = !self.playButton.selected;
}

- (void)valueChange:(UISlider *)progress other:(UIEvent *)event {
    float nowtime = progress.value * _videoLength;
    [_player seekToTime:CMTimeMake(nowtime * 10000, 10000)];
    NSInteger minit = nowtime / 60;
    NSInteger second = nowtime - 60 * minit;
    NSInteger endMinit = (_videoLength - nowtime) / 60;
    NSInteger endSecond = (_videoLength - nowtime) - 60 * endMinit;
    self.startTime.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minit, (long)second];
    self.endTime.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)endMinit, (long)endSecond];
}

- (void)changeValueBegin:(UISlider *)progress {
    _playButton.selected = YES;
    [_player pause];
}

- (void)changeVauleCancel:(UISlider *)progress {
    _playButton.selected = NO;
    [_player play];
}

- (void)backAction {
    [_player pause];
    [_request clearDelegatesAndCancel];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - KVO
- (void)addVideoKVO
{
    //KVO
    [_item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
}
- (void)removeVideoKVO {
    [_item removeObserver:self forKeyPath:@"status"];
    [_item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self
     
                                             selector:@selector(playerItemDidReachEnd:)
     
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
     
                                               object:self.item];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    self.playButton.selected = YES;
    [self.player pause];
}

- (void)removeNotification {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context {
    
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = _item.status;
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:
            {
                NSLog(@"AVPlayerItemStatusReadyToPlay");
                [_player play];
                _playButton.selected = NO;
                _videoLength = CMTimeGetSeconds(_player.currentItem.duration);
            }
                break;
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"AVPlayerItemStatusUnknown");
            }
                break;
            case AVPlayerItemStatusFailed:
            {
                NSLog(@"AVPlayerItemStatusFailed");
                NSLog(@"%@",_item.error);
            }
                break;
                
            default:
                break;
        }
    }
}

#pragma mark - TimerObserver
- (void)addVideoTimerObserver {
    __weak typeof (self)weakSelf = self;
    _timeObser = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        float timeDesc = CMTimeGetSeconds(time);
        NSInteger minit = timeDesc / 60;
        NSInteger second = timeDesc - 60 * minit;
        NSInteger endMinit = (_videoLength - timeDesc) / 60;
        NSInteger endSecond = (_videoLength - timeDesc) - 60 * endMinit;
        weakSelf.startTime.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)minit, (long)second];
        weakSelf.endTime.text = [NSString stringWithFormat:@"%02ld:%02ld", (long)endMinit, (long)endSecond];
        
        weakSelf.progressSlider.value = timeDesc / _videoLength;
    }];
}

- (void)removeVideoTimerObserver {
    NSLog(@"%@",NSStringFromSelector(_cmd));
    [_player removeTimeObserver:_timeObser];
}

#pragma mark - Network
- (void)downloadFile {
    NSString *urlString = _request.url.absoluteString;
//    NSString* filePath = [DYUtility getFilePath:[DYUtility getFileName:urlString]];
    NSString *filePath = [DYUtility getFilePathWithURL:urlString];
    NSString *tempPath = [DYUtility getFileCachePath:[DYUtility getFileName:urlString]];
    [_request setDownloadDestinationPath:filePath];
    [_request setTemporaryFileDownloadPath:tempPath];
    [_request setAllowResumeForFileDownloads:YES];
    _request.downloadProgressDelegate = self;
    if ([urlString hasPrefix:@"https://"]||[urlString hasPrefix:@"HTTPS://"])
    {
        [_request setValidatesSecureCertificate:NO];
    }
    [_request setDelegate:self];
    [_request setDownloadProgressDelegate:self];
    [_request addRequestHeader:@"Accept-Language" value:[NSString stringWithFormat:@"%@-%@",[MobileData sharedInstance].clientLanguage,[MobileData sharedInstance].clientCountry]];
    [_request setDidFinishSelector:@selector(downloadFileDone:)];
    [_request setDidFailSelector:@selector(downloadFileFailed:)];
    [_request setDefaultResponseEncoding:NSUTF8StringEncoding];
    [_progresshud show:YES];
    [_request startAsynchronous];
}

#pragma mark - ASIHttpRequestDelegate
- (void)downloadFileDone:(ASIHTTPRequest *)requestFile {
    [_progresshud hide:YES];
    
    NSDictionary* dict = requestFile.responseString.JSONValue;
    if (dict && [[NSString stringWithFormat:@"%@",dict[@"status"]] isEqualToString:@"-2"]) {
        [AlertView alertDownHUDWithMessage:dict[@"msg"] view:APPDELEGATE.window isBigFont:NO];
        return;
    }
    NSString *urlstring = [requestFile.url absoluteString];
    NSString* filePath = [DYUtility getFilePathWithURL:urlstring];
    [[WFDownloadCache shareDownloadCache] cacheFile:requestFile.url.absoluteString];
    [self showPlayer:[NSURL fileURLWithPath:filePath]];
}

- (void)downloadFileFailed:(ASIHTTPRequest *)requestFile {
    [_progresshud hide:YES];
    
    NSDictionary* dict = requestFile.responseString.JSONValue;
    if (dict && [[NSString stringWithFormat:@"%@",dict[@"status"]] isEqualToString:@"-2"]) {
        [AlertView alertDownHUDWithMessage:dict[@"msg"] view:APPDELEGATE.window isBigFont:NO];
        return;
    }
}

- (void)setProgress:(float)newProgress {
    _progresshud.progress = newProgress;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
        {
            [self downloadFile];
        }
            break;
        case 1:
        {
            [self backAction];
        }
            break;
        default:
            break;
    }
}

@end
