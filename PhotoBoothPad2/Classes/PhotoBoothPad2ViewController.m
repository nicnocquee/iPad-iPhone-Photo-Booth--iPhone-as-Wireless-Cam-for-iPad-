//
//  PhotoBoothPad2ViewController.m
//  PhotoBoothPad2
//
//  Created by Nico Prananta on 9/8/10.
//  Copyright Yumecraft 2010. All rights reserved.
//

#import "PhotoBoothPad2ViewController.h"
#import "MyImageView.h"
#import "TCPServer.h"
#import "PacketCategories.h"
#import "PickerController.h"
#import <QuartzCore/QuartzCore.h>
#import "MyActivityIndicator.h"

#define kGameIdentifier		@"photobooth"
#define kBufferSize 1024
#define kIndicatorCenterIpadX 384
#define kIndicatorCenterIpadY 512

@interface PhotoBoothPad2ViewController ()
- (void) setup;
- (void) presentPicker:(NSString *)name;
- (void) send:(const uint8_t)message;
- (void) openStreams;
@end

@interface PhotoBoothPad2ViewController (TCPServerDelegate) <TCPServerDelegate>
@end

@implementation PhotoBoothPad2ViewController

@synthesize imageView;
@synthesize pickerController;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	NSLog(@"ViewDidLoad");
	[self setWantsFullScreenLayout:YES];
	self.imageView = [[MyImageView alloc] initWithFrame:CGRectMake(0, 0, 768, 1024)];
	[self.imageView setUserInteractionEnabled:YES];
	[self.imageView setDelegate:self];
	[self.imageView becomeFirstResponder];
	[self.view addSubview:imageView];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
	[label setTextColor:[UIColor whiteColor]];
	[label setFont:[UIFont systemFontOfSize:30]];
	[label setBackgroundColor:[UIColor clearColor]];
	[label setText:@"Touch to start"];
	[label sizeToFit];
	[label setTag:101];
	[label setCenter:CGPointMake(384, 512)];
	[label.layer setTransform:CATransform3DMakeRotation(M_PI*1.5, 0, 0, 1)];
	[self.imageView addSubview:label];
	[label release];
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated{
	NSLog(@"ViewDidAppear");
	[self setup];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[imageView release];
	[pickerController release];
    [super dealloc];
}

#pragma mark --
#pragma mark Alert

- (void) _showAlert:(NSString *)title
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self setup];
}

#pragma mark --
#pragma mark Picker

- (void) setup {
	NSLog(@"Setup");
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
	if(_server == nil || ![_server start:&error]) {
		NSLog(@"Failed creating server: %@", error);
		[self _showAlert:@"Failed creating server"];
		return;
	}
	
	//Start advertising to clients, passing nil for the name to tell Bonjour to pick use default name
	if(![_server enableBonjourWithDomain:@"local" applicationProtocol:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier] name:nil]) {
		[self _showAlert:@"Failed advertising server"];
		return;
	}
	
	[self presentPicker:nil];
}

- (void) presentPicker:(NSString *)name{
	if (!pickerController) {
		PickerController *_pickerController = [[PickerController alloc] initWithType:[TCPServer bonjourTypeFromIdentifier:kGameIdentifier]];
		[_pickerController setDelegate:self];
		_pickerController.gameName = name;
		
		[_pickerController setModalPresentationStyle:UIModalPresentationFormSheet];
		[self presentModalViewController:_pickerController animated:YES];
		self.pickerController = _pickerController;
		self.pickerController.delegate = self;
		[_pickerController release];
	}
	self.pickerController.gameName = name;
}

- (void) destroyPicker{
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark --
#pragma mark BrowserViewControllerDelegate

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

#pragma mark -
#pragma mark MyImageViewDelegate

- (void)touchEnded{
	if (_outStream) {
		[self send:100];
		[self performSelector:@selector(showSendToPrinter) withObject:nil afterDelay:0.5];
	}
}

- (void)showSendToPrinter{
	MyActivityIndicator *ind = [[MyActivityIndicator alloc] initWithText:@"STAY STILL"];
	ind.tag = 999;
	[ind startAnimation];
	ind.center = CGPointMake(kIndicatorCenterIpadX, kIndicatorCenterIpadY);
	[ind.layer setTransform:CATransform3DMakeRotation(M_PI*1.5, 0, 0, 1)];
	[self.view addSubview:ind];
	[ind release];
}

#pragma mark --
#pragma mark Streams

- (void) openStreams
{
	_inStream.delegate = self;
	[_inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_inStream open];
	_outStream.delegate = self;
	[_outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[_outStream open];
}

- (void) send:(const uint8_t)message
{
	if (_outStream && [_outStream hasSpaceAvailable]){
		if([_outStream write:(const uint8_t *)&message maxLength:sizeof(const uint8_t)] == -1){
			[self _showAlert:@"Failed sending data to peer"];
		}
	}
}

@end


#pragma mark --
#pragma mark NSStream Delegate

@implementation PhotoBoothPad2ViewController (NSStreamDelegate)

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
				if ([_inStream hasBytesAvailable]) {
					NSMutableData *data = [NSMutableData data];
					if (readLeftover != nil) {
						[data appendData:readLeftover];
						[readLeftover release];
						readLeftover = nil;
					}
					
					NSInteger bytesRead;
					static uint8_t buffer[kBufferSize];
					
					bytesRead = [_inStream read:buffer maxLength:kBufferSize];
					if (bytesRead == -1) {
						NSLog(@"Something wrong here");
						return;
					} else if (bytesRead > 0){
						[data appendBytes:buffer length:bytesRead];
						NSArray *dataPackets = [data splitTransferredPackets:&readLeftover];
						if (readLeftover) {
							[readLeftover retain];
						}
						for (NSData *onePacketData in dataPackets) {
							UIImage *image = [UIImage imageWithData:onePacketData];
							if (image) {
								NSLog(@".");
								if ([self.view viewWithTag:999]) {
									MyActivityIndicator *myAct = (MyActivityIndicator *)[self.view viewWithTag:999];
									[myAct removeFromSuperview];
									UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 50)];
									[label setTextColor:[UIColor whiteColor]];
									[label setFont:[UIFont systemFontOfSize:30]];
									[label setBackgroundColor:[UIColor clearColor]];
									[label setText:@"Touch screen to start"];
									[label sizeToFit];
									[label setTag:101];
									[label setCenter:CGPointMake(384, 512)];
									[label.layer setTransform:CATransform3DMakeRotation(M_PI*1.5, 0, 0, 1)];
									[self.imageView addSubview:label];
									[label release];
								}
								[self.imageView setImage:image];
							}
						}
					}
					
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
@implementation PhotoBoothPad2ViewController (TCPServerDelegate)

- (void) serverDidEnableBonjour:(TCPServer *)server withName:(NSString *)string
{
	NSLog(@"%s", _cmd);
	[self presentPicker:string];
}

- (void)didAcceptConnectionForServer:(TCPServer *)server inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr
{
	NSLog(@"did accept connection for server");
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

@end
