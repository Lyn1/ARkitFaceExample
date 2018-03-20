//
//  ViewController.m
//  ARkitFaceExample
//
//  Created by Wence on 2018/3/19.
//  Copyright © 2018年 ZOOM. All rights reserved.
//

#import "ViewController.h"
#import <ARKit/ARKit.h>
#import "VirtualContentUpdater.h"
#import "WXHARRecorder.h"
#import <AVKit/AVKit.h>

@interface ViewController ()<ARSessionDelegate>

@property (strong, nonatomic) ARSCNView *sceneView;
@property (nonatomic, strong) VirtualContentUpdater* updater;
@property (nonatomic, strong) WXHARRecorder *recorder;
@property (nonatomic, strong) AVPlayerViewController* playerViewController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _sceneView = [[ARSCNView alloc] initWithFrame:self.view.bounds];
    _updater = [[VirtualContentUpdater alloc] init];
    _sceneView.delegate = _updater;
    _sceneView.session.delegate = self;
    _sceneView.automaticallyUpdatesLighting = true;
    [self.view addSubview:_sceneView];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(0, 0, 100, 100);
    [backButton setTitle:@"back" forState:UIControlStateNormal];
    backButton.backgroundColor = [UIColor brownColor];
  //  [backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    
    UIButton *setupbutton = [UIButton buttonWithType:UIButtonTypeCustom];
    [setupbutton setTitle:@"setup session" forState:UIControlStateNormal];
    setupbutton.frame = CGRectMake(0, 0, 200, 100);
    setupbutton.center = self.view.center;
    setupbutton.backgroundColor = [UIColor redColor];
    [setupbutton addTarget:self action:@selector(setupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:setupbutton];
    
    UIButton *startButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startButton.backgroundColor = [UIColor brownColor];
    [startButton setTitle:@"start Recorder" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    startButton.frame = CGRectMake(0, 0, 200, 100);
    startButton.center = CGPointMake(setupbutton.center.x, setupbutton.center.y+150);
    [self.view addSubview:startButton];
}

//first step,start session
- (void)setupButtonAction:(UIButton *)button
{
    if (self.recorder.status == WXHARRecorderStatusUnknown) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                NSError *error;
                if ([self.recorder setupSession:&error]) {
                    [self.recorder startSession];
                    button.backgroundColor = [UIColor greenColor];
                } else {
                    WRITERLOG(@"Error: %@", [error localizedDescription]);
                }
            } else {
                NSLog(@"Microphone or Camera doesn't allowed");
            }
        }];
    }
}

//second step, start recorder
- (void)startButtonAction:(UIButton *)button
{
    if (self.recorder.status != WXHARRecorderStatusUnknown) {
        button.selected = !button.selected;
        if (button.selected) {
            [button setTitle:@"end Recorder" forState:UIControlStateNormal];
            [self.recorder startRecording:self.sceneView];
        } else {
            [button setTitle:@"start Recorder" forState:UIControlStateNormal];
            [self.recorder stopRecording:^(NSURL *filePath) {
                NSLog(@"%@",filePath);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    AVPlayer *player = [AVPlayer playerWithURL:filePath];
                    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
                    playerViewController.player = player;
                    self.playerViewController = playerViewController;
                    [self presentViewController:playerViewController animated:YES completion:nil];
                    [playerViewController.player play];
                });
            }];
        }
    } else {
        NSLog(@"must be setup recorder session");
    }
}

- (ARSession *)session
{
    return _sceneView.session;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    ARFaceTrackingConfiguration *configuration = [[ARFaceTrackingConfiguration alloc] init];
    configuration.lightEstimationEnabled = YES;
    [[self session] runWithConfiguration:configuration options:ARSessionRunOptionResetTracking | ARSessionRunOptionRemoveExistingAnchors];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.sceneView.session pause];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    _sceneView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setter / Getter
- (WXHARRecorder *)recorder
{
    if (!_recorder) {
        _recorder = [[WXHARRecorder alloc] init];
    }
    return _recorder;
}

//暂时不支持横盘录制，会出现问题
- (BOOL)shouldAutorotate
{
    return NO;
}

@end
