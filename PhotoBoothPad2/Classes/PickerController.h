//
//  PickerController.h
//  PhotoBoothPad2
//
//  Created by Nico Prananta on 9/8/10.
//  Copyright 2010 Yumecraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowserViewController.h"
@class BrowserViewController;

@interface PickerController : UIViewController {
	NSString *typeNet;
@private
	UILabel *_gameNameLabel;
	BrowserViewController *_bvc;
}

@property (nonatomic, assign) id<BrowserViewControllerDelegate> delegate;
@property (nonatomic, copy) NSString *gameName;
@property (nonatomic, retain) NSString *typeNet;

- (id)initWithType:(NSString *)type;

@end
