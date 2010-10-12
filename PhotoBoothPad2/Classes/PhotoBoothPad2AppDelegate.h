//
//  PhotoBoothPad2AppDelegate.h
//  PhotoBoothPad2
//
//  Created by Nico Prananta on 9/8/10.
//  Copyright Yumecraft 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhotoBoothPad2ViewController;

@interface PhotoBoothPad2AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    PhotoBoothPad2ViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet PhotoBoothPad2ViewController *viewController;

@end

