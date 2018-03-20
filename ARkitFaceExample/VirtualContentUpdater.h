//
//  VirtualContentUpdater.h
//  ARkitFaceExample
//
//  Created by Wence on 2018/3/19.
//  Copyright © 2018年 ZOOM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>
#import "RobotHead.h"

@interface VirtualContentUpdater : NSObject <ARSCNViewDelegate>

//@property(nonatomic, assign) BOOL showsCoordinateOrigin;
@property(nonatomic, strong) RobotHead *robotHead;
@property(nonatomic, strong) dispatch_queue_t serialQueue;

@end
