//
//  WXHARRecorder.m
//  ARRecorder
//
//  Created by Wence on 2018/2/27.
//  Copyright © 2018年 Wence. All rights reserved.
//

#import "WXHARRecorder.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ARKit/ARKit.h>


@interface WXHARRecorder()<AVCaptureAudioDataOutputSampleBufferDelegate>
@property (nonatomic, strong) WXHAssetWriter *assetWriter;
@property (nonatomic, strong) AVCaptureSession *captureSession;//录制音频
@property (nonatomic, strong) dispatch_queue_t recorderQueue;


@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) CGSize bufferSize;
@property (nonatomic, strong) SCNRenderer *renderer;
@end
@implementation WXHARRecorder
- (instancetype)init
{
    self = [super init];
    if (self) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        CGFloat height = [UIScreen mainScreen].bounds.size.height;
        self.bufferSize = CGSizeMake(width, height);
        
        self.recorderQueue = dispatch_queue_create("com.recorder.video.queue", NULL);
    }
    return self;
}

- (BOOL)setupSession:(NSError **)error
{
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = [self sessionPreset];
    self.captureSession.usesApplicationAudioSession = YES;
    self.captureSession.automaticallyConfiguresApplicationAudioSession = NO;
    
    if (![self setupSessionInputs:error]) {
        return NO;
    }
    if (![self setupSessionOutputs:error]) {
        return NO;
    }
    self.status = WXHARRecorderStatusReady;
    return YES;
}
- (BOOL)setupSessionInputs:(NSError **)error
{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
    
    if (audioInput) {
        if ([self.captureSession canAddInput:audioInput]) {
            [self.captureSession addInput:audioInput];
        } else {
            *error = [NSError errorWithDomain:@""
                                         code:1000
                                     userInfo:@{NSLocalizedDescriptionKey : @"capture session failed to add audio input."}];
            return NO;
        }
    } else {
        return NO;
    }
    return YES;
}
- (BOOL)setupSessionOutputs:(NSError **)error
{
    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    [audioDataOutput setSampleBufferDelegate:self queue:self.recorderQueue];
    
    if ([self.captureSession canAddOutput:audioDataOutput]) {
        [self.captureSession addOutput:audioDataOutput];
    } else {
        *error = [NSError errorWithDomain:@""
                                     code:1000
                                 userInfo:@{NSLocalizedDescriptionKey : @"capture session failed to add audio output."}];
        return NO;
    }
    
    NSDictionary *videoSettings = @{AVVideoCodecKey:AVVideoCodecTypeH264,
                                    AVVideoWidthKey:@(self.bufferSize.width),
                                    AVVideoHeightKey:@(self.bufferSize.height)};
    
    NSDictionary *audioSettings = [audioDataOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
    
    self.assetWriter = [[WXHAssetWriter alloc] initWithVideoSettings:videoSettings
                                                       audioSettings:audioSettings
                                                       dispatchQueue:self.recorderQueue];
    return YES;
}
- (void)startSession
{
    __weak WXHARRecorder *weakSelf = self;
    
    dispatch_async(self.recorderQueue, ^{
        [weakSelf setupAudioSession];
        if (![weakSelf.captureSession isRunning]) {
            [weakSelf.captureSession startRunning];
        }
    });
}
- (void)stopSession
{
    __weak WXHARRecorder *weakSelf = self;
    dispatch_async(self.recorderQueue, ^{
        if ([weakSelf.captureSession isRunning]) {
            [weakSelf.captureSession stopRunning];
        }
    });
}

- (NSString *)sessionPreset {
    return AVCaptureSessionPresetHigh;
}

- (void)setupAudioSession
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionMixWithOthers |
    AVAudioSessionCategoryOptionAllowBluetooth |
    AVAudioSessionCategoryOptionDefaultToSpeaker |
    AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers;
    
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                  withOptions:options
                        error:&error];
    if (error) {
        WRITERLOG(@"%@",[error localizedDescription]);
    }
    [audioSession setActive:YES error:&error];
    if (error) {
        WRITERLOG(@"%@",[error localizedDescription]);
    }
}

- (void)renderFrame
{
    __weak WXHARRecorder *weakSelf = self;
    dispatch_sync(self.recorderQueue, ^{
        if (self.assetWriter.isWriting) {
            CVPixelBufferRef buffer = [weakSelf createCapturePixelBuffer];
            [self.assetWriter appendPixelBuffer:buffer];
            CVPixelBufferRelease(buffer);
        }
    });
}

- (void)setScene:(SCNScene *)scene
{
    self.renderer.scene = scene;
}

- (void)startRecording:(ARSCNView *)scnView
{
    if (self.status == WXHARRecorderStatusReady || self.status == WXHARRecorderStatusCompleted) {
        self.status = WXHARRecorderStatusRecording;
        self.renderer.scene = scnView.scene;

        [self.assetWriter startWriting];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop]
                               forMode:NSRunLoopCommonModes];
    }
}

- (void)stopRecording:(CompletionHeander)hander
{
    if (self.status == WXHARRecorderStatusRecording) {
        self.status = WXHARRecorderStatusCompleted;
        [self.displayLink removeFromRunLoop:[NSRunLoop mainRunLoop]
                                    forMode:NSRunLoopCommonModes];
        [self stopSession];
        [self.assetWriter stopWriting:hander];
    }
}

//生成CVPixelBufferRef，需要CVPixelBufferRelease
-(CVPixelBufferRef)createCapturePixelBuffer
{
    CFTimeInterval time = CACurrentMediaTime();
    UIImage *image = [self.renderer snapshotAtTime:time
                                          withSize:CGSizeMake(self.bufferSize.width, self.bufferSize.height)
                                  antialiasingMode:SCNAntialiasingModeMultisampling4X];

    CVPixelBufferRef pixelBuffer = NULL;
    
//    CFStringRef keys[2] = {kCVPixelBufferCGImageCompatibilityKey, kCVPixelBufferCGBitmapContextCompatibilityKey};
//    CFBooleanRef values[2] = {kCFBooleanTrue,kCFBooleanTrue};
//
//    CFDictionaryRef dictionaryRef = CFDictionaryCreate(kCFAllocatorDefault,
//                                                         (void*)keys,
//                                                         (void*)values,
//                                                         2,
//                                                         &kCFTypeDictionaryKeyCallBacks,
//                                                         &kCFTypeDictionaryValueCallBacks);
//
//    CVPixelBufferCreate(kCFAllocatorDefault,
//                        self.bufferSize.width,
//                        self.bufferSize.height,
//                        kCVPixelFormatType_32BGRA,
//                        dictionaryRef,
//                        &pixelBuffer);
    
    CVPixelBufferPoolCreatePixelBuffer(NULL, [self.assetWriter.pixelBufferAdaptor pixelBufferPool], &pixelBuffer);
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    
    CGContextRef context = CGBitmapContextCreate(data,
                                                 self.bufferSize.width,
                                                 self.bufferSize.height,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pixelBuffer),
                                                 CGColorSpaceCreateDeviceRGB(),
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, self.bufferSize.width, self.bufferSize.height), image.CGImage);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CGContextRelease(context);
    
    return pixelBuffer;
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    [self.assetWriter appendSampleBuffer:sampleBuffer];
}

#pragma mark - Setter / Getter
- (SCNRenderer *)renderer
{
    if (!_renderer) {
        _renderer = [SCNRenderer rendererWithDevice:nil options:nil];
    }
    return _renderer;
}

- (CADisplayLink *)displayLink
{
    if (!_displayLink) {
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(renderFrame)];
        _displayLink.preferredFramesPerSecond = 30;//30帧每s
    }
    return _displayLink;
}
@end
