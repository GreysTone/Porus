//
//  ViewController.m
//  Porus
//
//  Created by GreysTone on 2016-11-25.
//  Copyright © 2016 Danyang Song (Arthur). All rights reserved.
//

#import "ViewController.h"

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
  
//  self.previewLayer.frame = CGRectMake(0, 0, self.cameraView.bounds.size.height, self.cameraView.bounds.size.width);
//  self.cameraView.layer.masksToBounds = YES;
  CGAffineTransform transform = CGAffineTransformMakeRotation(-M_PI_2);
  self.cameraView.layer.affineTransform = transform;
  self.previewLayer.frame = self.cameraView.bounds;
  [self.cameraView.layer addSublayer:self.previewLayer];
  self.cameraView.layer.masksToBounds = YES;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self initAVCaptureSession];
  
  self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];

}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
  AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
  if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
    result = AVCaptureVideoOrientationLandscapeRight;
  else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
    result = AVCaptureVideoOrientationLandscapeLeft;
  return result;
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
    AVCaptureConnection *stillImageConnection = [self.frameOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [stillImageConnection setVideoOrientation:avcaptureOrientation];
//    [stillImageConnection setVideoScaleAndCropFactor:self.effectiveScale];
    AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettings];
//    [self.frameOutput set]
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
    [self.frameView setImage: self.capturedFrame];
    self.logText.text = [self.logText.text stringByAppendingString:@"Captured frame\n"];
    [self.logText scrollRangeToVisible:NSMakeRange(self.logText.text.length,0)];
  }
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
