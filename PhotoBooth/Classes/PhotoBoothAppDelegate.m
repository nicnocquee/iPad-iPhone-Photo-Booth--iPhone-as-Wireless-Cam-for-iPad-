//
//  PhotoBoothAppDelegate.m
//  PhotoBooth
//
//  Created by Nico Prananta on 9/4/10.
//  Copyright Yumecraft 2010. All rights reserved.
//

#import "PhotoBoothAppDelegate.h"
#import "Picker.h"
#import "PacketCategories.h"
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import "S7FTPRequest.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define kServiceIdentifier @"photobooth"
#define macFTPAddress @"ftp://192.168.1.103/tmp/" //the address of your FTP server
#define macFTPUsername @"your_ftp_username_here"
#define macFTPPassword @"your_ftp_password_here"

@interface PhotoBoothAppDelegate ()
- (void) setup;
- (void) presentPicker:(NSString *)name;
- (void) sendQueuedData:(NSOutputStream *)outStream;
- (BOOL) sendData:(NSData *)data error:(NSError **)error withStream:(NSOutputStream *)outStream;
- (void) initCapture;
- (void) snapAndSendToPrint;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
@end


@interface PhotoBoothAppDelegate (NSStreamDelegate) <NSStreamDelegate>
@end

@implementation PhotoBoothAppDelegate

@synthesize _window;
@synthesize imageView;
@synthesize captureSession = _captureSession;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize videoDataOutput = _videoDataOutput;
@synthesize captureInput = _captureInput;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	
    [_window makeKeyAndVisible];
	[self initCapture];
	[self setup];
	
	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
	NSLog(@"receive memory warning");
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
	[self.captureSession stopRunning];
	[self.captureSession release];
	[self.captureInput release];
	[self.videoDataOutput release];
	[self.stillImageOutput release];
	[ftpRequest release];
	[imageView release];
	[packetQueue release];
	[writeLeftover release];
    [_window release];
    [super dealloc];
}

#pragma mark -
#pragma mark Stuffs

- (void)initCapture {
	/*We setup the input*/
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput 
										  deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] 
										  error:nil];
	[self setCaptureInput:captureInput];
	/*We setupt the output*/
	AVCaptureVideoDataOutput *captureOutput = [[AVCaptureVideoDataOutput alloc] init]; 
	captureOutput.alwaysDiscardsLateVideoFrames = YES; 
	[captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey; 
	NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]; 
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:value forKey:key]; 
	[captureOutput setVideoSettings:videoSettings]; 
	
	AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:
                                    AVVideoCodecJPEG, AVVideoCodecKey,
                                    nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [outputSettings release];
    
	/*And we create a capture session*/
	self.captureSession = [[AVCaptureSession alloc] init];
	[self.captureSession addInput:self.captureInput];
	[self.captureSession addOutput:captureOutput];
	[self.captureSession addOutput:stillImageOutput];
	self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
	/*We start the capture*/
	[self.captureSession startRunning];
	
	[self setStillImageOutput:stillImageOutput];
	[stillImageOutput release];
	[self setVideoDataOutput:captureOutput];
	[captureOutput release];
}
- (void) _showAlert:(NSString *)title
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}


- (void) setup{
	NSLog(@"setup");
	[_server release];
	_server = nil;
	
	[_inStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream release];
	_inStream = nil;
	_inReady = NO;
	
	[_outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream release];
	_outStream = nil;
	_outReady = NO;
	
	_server = [TCPServer new];
	[_server setDelegate:self];
	NSError *error;
	if (_server == nil || ![_server start:&error]) {
		NSLog(@"failed creating server: %@", error);
		[self _showAlert:@"Failed creating server"];
		return;
	}
	
	if (![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kServiceIdentifier] name:nil]) {
		[self _showAlert:@"failed advertising server"];
		return;
	}
	
	packetQueue = [[NSMutableArray alloc] init];
	
	ftpRequest = [[S7FTPRequest alloc] initUploadWithURL:[NSURL URLWithString:macFTPAddress]];
	ftpRequest.username = macFTPUsername;
	ftpRequest.password = macFTPPassword;
	
	ftpRequest.delegate = self;
	ftpRequest.didFinishSelector = @selector(uploadFinished:);
	ftpRequest.didFailSelector = @selector(uploadFailed:);
	ftpRequest.willStartSelector = @selector(uploadWillStart:);
	ftpRequest.didChangeStatusSelector = @selector(requestStatusChanged:);
	ftpRequest.bytesWrittenSelector = @selector(uploadBytesWritten:);
}

- (void) presentPicker:(NSString *)name {
	if (!_picker) {
		_picker = [[Picker alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] type:[TCPServer bonjourTypeFromIdentifier:kServiceIdentifier]];
		_picker.delegate = self;
	}
	
	_picker.gameName = name;
	
	if (!_picker.superview) {
		[_window addSubview:_picker];
	}
}

- (void) destroyPicker {
	[_picker removeFromSuperview];
	[_picker release];
	_picker = nil;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup];
}

- (BOOL)sendData:(NSData *)data error:(NSError **)error withStream:(NSOutputStream *)outStream {
	if (data == nil || [data length] == 0) return NO;
	[packetQueue addObject:data];
	if ([outStream hasSpaceAvailable]) [self sendQueuedData:outStream];
	return YES;
}


- (void) sendQueuedData:(NSOutputStream *)outStream {
	if (writeLeftover == nil && [packetQueue count]==0) {
		return; //Nothing to send
	}
	NSMutableData *dataToSend = [NSMutableData data];
	if (writeLeftover != nil) {
		[dataToSend appendData:writeLeftover];
		[writeLeftover release];
		writeLeftover = nil;
	}
	
	[dataToSend appendData:[packetQueue contentsForTransfer]];
	[packetQueue removeAllObjects];
	
	NSUInteger sendLength = [dataToSend length];
	NSUInteger written = [outStream write:[dataToSend bytes] maxLength:sendLength];
	
	//NSLog(@"Sent %d bytes", written);
	if (written == -1) {
		NSLog(@"Something wrong");
	}
	
	if (written != sendLength) {
		NSRange leftoverRange = NSMakeRange(written, [dataToSend length] - written);
		writeLeftover = [[dataToSend subdataWithRange:leftoverRange] retain];
	}
}

- (void) openStreams
{
		_inStream.delegate = self;
		[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_inStream open];
		_outStream.delegate = self;
		[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[_outStream open];
}

- (void) browserViewController:(BrowserViewController *)bvc didResolveInstance:(NSNetService *)netService
{
	if (!netService) {
		[self setup];
		return;
	}
	
	// note the following method returns _inStream and _outStream with a retain count that the caller must eventually release
	if (![netService getInputStream:&_inStream outputStream:&_outStream]) {
		[self _showAlert:@"Failed connecting to server"];
		return;
	}
	
	[self openStreams];
}

- (void) snapAndSendToPrint{
	AVCaptureConnection *videoConnection = [PhotoBoothAppDelegate connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
	[videoConnection setEnabled:YES];
	
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                             if (imageDataSampleBuffer != NULL) {
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                
																 [ftpRequest setDataToSend:imageData];
																 [ftpRequest startRequest];
                                                             } else if (error) {
																 NSLog(@"Something's wrong");
                                                             }
                                                         }];
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return [[connection retain] autorelease];
			}
		}
	}
	return nil;
}

- (void)uploadFinished:(S7FTPRequest *)request {
	[self performSelector:@selector(reconnectVideoDataOutput) withObject:nil afterDelay:1.0];
}

- (void)reconnectVideoDataOutput{
	AVCaptureConnection *videoConnection = [PhotoBoothAppDelegate connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self videoDataOutput] connections]];
	[videoConnection setEnabled:YES];
	[self.captureSession beginConfiguration];
	self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
	[self.captureSession commitConfiguration];
	if (![self.captureSession isRunning]) {
		[self.captureSession startRunning];
	}
}

- (void)uploadFailed:(S7FTPRequest *)request {
	
	NSLog(@"Upload failed: %@", [request.error localizedDescription]);
	[request release];
}

- (void)uploadWillStart:(S7FTPRequest *)request {
	
	NSLog(@"Will transfer %d bytes.", request.fileSize);
}

- (void)uploadBytesWritten:(S7FTPRequest *)request {
	
	NSLog(@"Transferred: %d", request.bytesWritten);
}

- (void)requestStatusChanged:(S7FTPRequest *)request {
	
	switch (request.status) {
		case S7FTPRequestStatusOpenNetworkConnection:
			NSLog(@"Opened connection.");
			break;
		case S7FTPRequestStatusReadingFromStream:
			NSLog(@"Reading from stream...");
			break;
		case S7FTPRequestStatusWritingToStream:
			NSLog(@"Writing to stream...");
			break;
		case S7FTPRequestStatusClosedNetworkConnection:
			NSLog(@"Closed connection.");
			break;
		case S7FTPRequestStatusError:
			NSLog(@"Error occurred.");
			break;
	}
}
@end

#pragma mark -
@implementation PhotoBoothAppDelegate (NSStreamDelegate)
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventOpenCompleted:
		{
			[self destroyPicker];
			
			[_server release];
			_server = nil;
			
			if (stream == _inStream)
				_inReady = YES;
			else
				_outReady = YES;
			break;
		}
		case NSStreamEventHasBytesAvailable:
		{
			if (stream == _inStream) {
				uint8_t b;
				unsigned int len = 0;
				len = [_inStream read:&b maxLength:sizeof(uint8_t)];
				if(!len) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self _showAlert:@"Failed reading data from peer"];
				} else {
					AVCaptureConnection *videoConnection = [PhotoBoothAppDelegate connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self videoDataOutput] connections]];
					[videoConnection setEnabled:NO];
					[self.captureSession beginConfiguration];
					self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
					[self.captureSession commitConfiguration];
					[self performSelector:@selector(snapAndSendToPrint) withObject:nil afterDelay:0.1];
				}
			}
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			NSLog(@"%s", _cmd);
			[self _showAlert:@"Error encountered on stream!"];			
			break;
		}
		case NSStreamEventHasSpaceAvailable:
			if (stream == _outStream) {
				[self sendQueuedData:(NSOutputStream *)stream];
			}
			break;
		case NSStreamEventEndEncountered:
		{
			UIAlertView	*alertView;
			
			alertView = [[UIAlertView alloc] initWithTitle:@"Peer Disconnected!" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];
			
			break;
		}
	}
}

@end


#pragma mark -
@implementation PhotoBoothAppDelegate (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer *)server withName:(NSString *)string
{
	NSLog(@"%s", _cmd);
	[self presentPicker:string];
}

- (void)didAcceptConnectionForServer:(TCPServer *)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	if (_inStream || _outStream || server != _server)
		return;
	
	[_server release];
	_server = nil;
	
	_inStream = istr;
	[_inStream retain];
	_outStream = ostr;
	[_outStream retain];
	
	[self openStreams];
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
	/*Lock the image buffer*/
	CVPixelBufferLockBaseAddress(imageBuffer,0); 
	/*Get information about the image*/
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
	size_t width = CVPixelBufferGetWidth(imageBuffer); 
	size_t height = CVPixelBufferGetHeight(imageBuffer); 
	
	/*Create a CGImageRef from the CVImageBufferRef*/
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
	CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
	CGImageRef newImage = CGBitmapContextCreateImage(newContext); 
	/*We unlock the  image buffer*/
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	
	/*We release some components*/
	CGContextRelease(newContext); 
	CGColorSpaceRelease(colorSpace);
	
	/*We display the result on the image view (We need to change the orientation of the image so that the video is displayed correctly)*/
	UIImage *image = [[UIImage alloc] initWithCGImage:newImage scale:1 orientation:UIImageOrientationLeft];
	
	/*We relase the CGImageRef*/
	CGImageRelease(newImage);
	
	if (_outStream && image) {
		NSData *dat = UIImageJPEGRepresentation(image, 0.5);
		NSError *err;
		[self sendData:dat error:&err withStream:_outStream];
	}
	[image release];
} 

@end
