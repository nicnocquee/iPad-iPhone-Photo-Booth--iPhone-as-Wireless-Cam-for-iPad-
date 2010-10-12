//
//  PhotoBoothAppDelegate.h
//  PhotoBooth
//
//  Created by Nico Prananta on 9/4/10.
//  Copyright Yumecraft 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Picker.h"
#import "BrowserViewController.h"
#import "TCPServer.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import "S7FTPRequest.h"

@interface PhotoBoothAppDelegate : NSObject <UIApplicationDelegate, UIActionSheetDelegate,
BrowserViewControllerDelegate, TCPServerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate> {
    UIWindow *_window;
	Picker *_picker;
	TCPServer *_server;
	NSInputStream *_inStream;
	NSOutputStream *_outStream;
	BOOL _inReady;
	BOOL _outReady;
	BOOL _outReadyPrinter;
	
	NSMutableArray *packetQueue;
	NSData *writeLeftover;
	UIImageView *imageView;
	AVCaptureSession *_captureSession;
	AVCaptureStillImageOutput *_stillImageOutput;
	AVCaptureVideoDataOutput *_videoDataOutput;
	AVCaptureDeviceInput *_captureInput;
	
	S7FTPRequest *ftpRequest;
}

@property (nonatomic, retain) IBOutlet UIWindow *_window;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, retain) AVCaptureDeviceInput *captureInput;
@end

