//
//  WXHARRecorder.h
//  ARRecorder
//
//  Created by 伍小华 on 2018/2/27.
//  Copyright © 2018年 伍小华. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WXHAssetWriter.h"

typedef NS_ENUM(NSInteger, WXHARRecorderStatus) {
    WXHARRecorderStatusUnknown = 0,
    WXHARRecorderStatusReady,
    WXHARRecorderStatusRecording,
    WXHARRecorderStatusCompleted,
};

@class ARSCNView;
@interface WXHARRecorder : NSObject
@property (nonatomic, assign) WXHARRecorderStatus status;

- (BOOL)setupSession:(NSError **)error;
- (void)startSession;
- (void)startRecording:(ARSCNView *)scnView;
- (void)stopRecording:(CompletionHeander)hander;
@end
