//
//  VirtualContentUpdater.m
//  ARkitFaceExample
//
//  Created by Wence on 2018/3/19.
//  Copyright © 2018年 ZOOM. All rights reserved.
//

#import "VirtualContentUpdater.h"

@implementation VirtualContentUpdater 

- (instancetype)init
{
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("com.example.apple-samplecode.ARKitFaceExample.serialSceneKitQueue", 0);
        NSString *url = [[NSBundle mainBundle] pathForResource:@"robotHead" ofType:@"scn" inDirectory:nil];
        NSURL *url1 = [NSURL fileURLWithPath:url];
        _robotHead =  [RobotHead referenceNodeWithURL:url1];
    }
    
    return self;
}

- (void)setupFaceNodeContent:(SCNNode *)node
{
    [node.childNodes enumerateObjectsUsingBlock:^(SCNNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromParentNode];
    }];
    [node addChildNode:_robotHead];
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didAddNode:(SCNNode *)node forAnchor:(ARAnchor *)anchor
{
    dispatch_async(_serialQueue, ^{
        [self setupFaceNodeContent:node];
    });
}

- (void)renderer:(id <SCNSceneRenderer>)renderer didUpdateNode:(SCNNode *)node forAnchor:(ARFaceAnchor *)anchor
{
    [_robotHead update:anchor];
}

@end
