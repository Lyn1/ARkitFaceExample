//
//  RobotHead.h
//  ARkitFaceExample
//
//  Created by Wence on 2018/3/19.
//  Copyright © 2018年 ZOOM. All rights reserved.
//

#import <SceneKit/SceneKit.h>
#import <ARKit/ARKit.h>

@interface RobotHead : SCNReferenceNode 

@property(nonatomic, assign)CGFloat originalJawY;
@property(nonatomic, strong)SCNNode *jawNode;
@property(nonatomic, strong)SCNNode *eyeLeftNode;
@property(nonatomic, strong)SCNNode *eyeRightNode;

- (void)update:(ARFaceAnchor *)withFaceAnchor;

@end
