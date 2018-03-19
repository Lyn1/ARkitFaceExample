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

@interface ViewController ()<ARSessionDelegate>

@property (strong, nonatomic) ARSCNView *sceneView;
@property (nonatomic, strong) VirtualContentUpdater* updater;

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
    
    // Do any additional setup after loading the view, typically from a nib.
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

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    _sceneView.frame = self.view.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
