//
//  PacketCategories.h
//  PhotoBooth
//
//  Created by  Nico Prananta on 8/6/10.
//  Copyright 2010 Yumecraft. All rights reserved.
//

#import <Foundation/Foundation.h> 

#define kInvalidObjectException	@"Invalid Object Exception"

@interface NSArray(PacketSend) 

-(NSData *)contentsForTransfer; 

@end

@interface NSData(PacketSplit) 
- (NSArray *)splitTransferredPackets:(NSData **)leftover; 
@end