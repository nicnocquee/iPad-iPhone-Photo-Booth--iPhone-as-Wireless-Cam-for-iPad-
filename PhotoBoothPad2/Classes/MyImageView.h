//
//  MyImageView.h
//  PhotoBoothPad
//
//  Created by  Nico Prananta on 8/6/10.
//  Copyright 2010 Yumecraft. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MyImageViewDelegate <NSObject>
@required
- (void) touchEnded;
@end


@interface MyImageView : UIImageView {
	id<MyImageViewDelegate> _delegate;
	int _countDown;
}

@property (nonatomic, assign) id<MyImageViewDelegate> delegate;

@end
