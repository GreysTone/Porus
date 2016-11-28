//
//  ViewController.m
//  Porus
//
//  Created by GreysTone on 2016-11-25.
//  Copyright © 2016 Danyang Song (Arthur). All rights reserved.
//

#import "ViewController.h"

#import <AFNetworking/AFNetworking.h>

#define TIMER_INTERVAL 1.5

@interface ViewController ()

@end

@implementation ViewController

- (void)initAVCaptureSession{
  
  self.session = [[AVCaptureSession alloc] init];
  self.session.sessionPreset = AVCaptureSessionPreset1920x1080;
  
  NSError *error;
  
  // initialize camera
  AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  [device lockForConfiguration:nil];
  [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
  [device unlockForConfiguration];
  self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
  if (error) {
    NSLog(@"%@",error);
  }
  
  // setting capture configuration
  self.frameOutput = [[AVCapturePhotoOutput alloc] init];
  
  [self.session beginConfiguration];
  [self.session addInput:self.videoInput];
  [self.session addOutput:self.frameOutput];
  [self.session commitConfiguration];
  
  // setting cameraView
  self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
  [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
  self.previewLayer.frame = self.cameraView.bounds;
  [self.cameraView.layer addSublayer:self.previewLayer];
  self.cameraView.layer.masksToBounds = YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self initAVCaptureSession];
  
  self.timer = [NSTimer timerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];

}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:YES];
  
  if (self.session) {
    [self.session startRunning];
  }
  if (self.timer) {
    [self.timer setFireDate:[NSDate distantPast]];
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:YES];
  AVCaptureConnection *previewLayerConnection = self.previewLayer.connection;
  
  if ([previewLayerConnection isVideoOrientationSupported]) {
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    switch (orientation) {
      case UIInterfaceOrientationPortrait:
        break;
      case UIInterfaceOrientationPortraitUpsideDown:
        break;
      case UIInterfaceOrientationLandscapeLeft:
        [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        break;
      case UIInterfaceOrientationLandscapeRight:
        [previewLayerConnection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        break;
      case UIInterfaceOrientationUnknown:
        break;
    }
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:YES];
  
  if (self.session) {
    [self.session stopRunning];
  }
  if (self.timer) {
    [self.timer setFireDate:[NSDate distantFuture]];
    [self.timer invalidate];
    self.timer = nil;
  }
}

- (void)timerAction:(id)sender {
  if(self.session && self.session.isRunning) {
    AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettings];
    [self.frameOutput capturePhotoWithSettings:setting delegate:self];
  } else {
    NSLog(@"AVCaptureSession is not running");
  }
}

#pragma mark - AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
  if (error) {
    NSLog(@"error : %@", error.localizedDescription);
  }
  
  if (photoSampleBuffer) {
    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    self.capturedFrame = [UIImage imageWithData:data];
    CIImage *previewFrame = [[CIImage alloc] initWithData:data];
    UIImage *preview = [UIImage imageWithCIImage:previewFrame scale:1.0 orientation:UIImageOrientationRight];
    [self.frameView setImage: preview];
    self.logText.text = [self.logText.text stringByAppendingString:@"Captured frame\n"];
    [self.logText scrollRangeToVisible:NSMakeRange(self.logText.text.length,0)];
    
    [self uploadImage];
  }
}

- (void)uploadImage {
  AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  NSLog(@"Trigger network testing");
  
  NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@%@", @"http://", self.addressAndPort.text, @"/prediction/upload"];
  [manager POST:urlString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
    UIImage *image = self.capturedFrame;
    NSData *data = UIImageJPEGRepresentation(image, 0.8);
    [formData appendPartWithFileData:data name:@"file" fileName:@"target.jpg" mimeType:@"image/jpeg"];
    
  } progress:^(NSProgress * _Nonnull uploadProgress) {
    
    NSLog(@"%lf",1.0 *uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
    
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    
    NSLog(@"请求成功：%@",responseObject);
    NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    NSString *ret = [[NSString alloc] initWithFormat:@"Request Succeed：%@\n", result];
    self.logText.text = [self.logText.text stringByAppendingString:ret];
    [self.logText scrollRangeToVisible:NSMakeRange(self.logText.text.length,0)];
    self.predictResult.text = result;
    
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    
    NSLog(@"请求失败：%@",error);
    NSString *ret = [[NSString alloc] initWithFormat:@"Request Failed：%@\n", error];
    self.logText.text = [self.logText.text stringByAppendingString:ret];
    [self.logText scrollRangeToVisible:NSMakeRange(self.logText.text.length,0)];
  }];
}

- (IBAction)testNetwork:(id)sender {
  AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  NSLog(@"Connecting to the framework");
  
  NSString *urlString = [[NSString alloc] initWithFormat:@"%@%@%@", @"http://", self.addressAndPort.text, @"/prediction/index"];
  [manager GET:urlString parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
  } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
    NSString *result = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
    NSString *ret = [[NSString alloc] initWithFormat:@"Request Succeed：%@\n", result];
    self.logText.text = [self.logText.text stringByAppendingString:ret];
    [self.logText scrollRangeToVisible:NSMakeRange(self.logText.text.length,0)];
    self.predictResult.text = result;
  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    NSString *ret = [[NSString alloc] initWithFormat:@"Request Failed：%@\n", error];
    self.logText.text = [self.logText.text stringByAppendingString:ret];
    [self.logText scrollRangeToVisible:NSMakeRange(self.logText.text.length,0)];
  }];
}

- (IBAction)beginPredict:(id)sender {
  [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
  
  self.logText.text = [self.logText.text stringByAppendingString:@"Start predict\n"];
  [self.predictButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  [self.predictButton setEnabled:false];
  [self.pauseButton setEnabled:true];
  
}

- (IBAction)controlTimer:(id)sender {
  if ([self.pauseButton.titleLabel.text isEqual: @"Pause"]) {
    [self.timer setFireDate:[NSDate distantFuture]];
    self.logText.text = [self.logText.text stringByAppendingString:@"Pause tracking\n"];
    [self.pauseButton setTitle:@"Resume" forState:UIControlStateNormal];
  } else {
    [self.timer setFireDate:[NSDate distantPast]];
    self.logText.text = [self.logText.text stringByAppendingString:@"Resume tracking\n"];
    [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];

  }
}

- (IBAction)forceCapture:(id)sender {
  self.logText.text = [self.logText.text stringByAppendingString:@"Force capture frame\n"];
  
  AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettings];
  [self.frameOutput capturePhotoWithSettings:setting delegate:self];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


@end
