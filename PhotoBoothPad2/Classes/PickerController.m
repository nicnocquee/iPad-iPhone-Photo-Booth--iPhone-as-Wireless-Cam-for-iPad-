    //
//  PickerController.m
//  PhotoBoothPad2
//
//  Created by Nico Prananta on 9/8/10.
//  Copyright 2010 Yumecraft. All rights reserved.
//

#import "PickerController.h"

#define kOffset 5.0
#define kModalWidth 540

@interface PickerController ()
@property (nonatomic, retain, readwrite) BrowserViewController *bvc;
@property (nonatomic, retain, readwrite) UILabel *gameNameLabel;
@end


@implementation PickerController

@synthesize bvc = _bvc;
@synthesize gameNameLabel = _gameNameLabel;
@synthesize typeNet;

- (id)initWithType:(NSString *)_type{
	if (self = [super init]) {
		self.typeNet = _type;
	}
	return self;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
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
	NSLog(@"service Type : %@", self.typeNet);
	self.bvc = [[BrowserViewController alloc] initWithTitle:nil showDisclosureIndicators:NO showCancelButton:NO];
	[self.bvc searchForServicesOfType:self.typeNet inDomain:@"local"];
	
	self.view.opaque = YES;
	self.view.backgroundColor = [UIColor blackColor];
	
	UILabel* label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kModalWidth, 50)];
	[label setTextAlignment:UITextAlignmentCenter];
	[label setFont:[UIFont boldSystemFontOfSize:15.0]];
	[label setTextColor:[UIColor whiteColor]];
	[label setShadowColor:[UIColor colorWithWhite:0.0 alpha:0.75]];
	[label setShadowOffset:CGSizeMake(1,1)];
	[label setBackgroundColor:[UIColor clearColor]];
	label.text = @"Waiting for the iPhone to connect";
	label.numberOfLines = 1;
	[self.view addSubview:label];
	
	[self.bvc.view setFrame:CGRectMake(0, label.frame.size.height, self.view.bounds.size.width, self.view.bounds.size.height)];
	[self.view addSubview:self.bvc.view];
    [super viewDidLoad];
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[typeNet dealloc];
    [super dealloc];
}

- (id<BrowserViewControllerDelegate>)delegate {
	return self.bvc.delegate;
}

- (void)setDelegate:(id<BrowserViewControllerDelegate>)delegate {
	[self.bvc setDelegate:delegate];
}

- (NSString *)gameName {
	return self.gameNameLabel.text;
}

- (void)setGameName:(NSString *)string {
	[self.gameNameLabel setText:string];
	[self.bvc setOwnName:string];
}



@end
