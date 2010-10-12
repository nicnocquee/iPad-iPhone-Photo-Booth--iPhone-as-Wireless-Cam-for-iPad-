//
//  PhotoBoothPad2ViewController.h
//  PhotoBoothPad2
//
//  Created by Nico Prananta on 9/8/10.
//  Copyright Yumecraft 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyImageView.h"
#import "BrowserViewController.h"

@class MyImageView;
@class TCPServer;
@class PickerController;

@interface PhotoBoothPad2ViewController : UIViewController <MyImageViewDelegate, BrowserViewControllerDelegate>{
	TCPServer			*_server;
	NSInputStream		*_inStream;
	NSOutputStream		*_outStream;
	BOOL				_inReady;
	BOOL				_outReady;
	BOOL				_readLength;
	int					_dataLength;
	
	NSData *readLeftover;
	MyImageView *imageView;
	
	PickerController *pickerController;
}

@property (nonatomic, retain) MyImageView *imageView;
@property (nonatomic, retain) PickerController *pickerController;

@end

