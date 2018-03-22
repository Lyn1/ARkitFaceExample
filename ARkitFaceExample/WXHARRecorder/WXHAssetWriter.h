//
//  WXHAssetWriter.h
//  ARRecorder
//
//  Created by Wence on 2018/3/1.
//  Copyright © 2018年 Wence. All rights reserved.
//

//DEBUG 模式下打印日志,当前行
#ifdef DEBUG
# define WRITERLOG(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
# define WRITERLOG(...)
#endif

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void (^CompletionHeander)(NSURL *filePath);

@interface WXHAssetWriter : NSObject
@property (nonatomic, assign, readonly) BOOL isWriting;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *pixelBufferAdaptor;


- (instancetype)initWithVideoSettings:(NSDictionary *)videoSettings
                        audioSettings:(NSDictionary *)audioSettings
                        dispatchQueue:(dispatch_queue_t)dispatchQueue;

- (void)startWriting;
- (void)stopWriting:(CompletionHeander)completionHander;

- (void)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end
