//
//  ViewController.m
//  TangramiOS
//
//  Created by Matt Blair on 8/25/14.
//  Copyright (c) 2014 Mapzen. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    
}
@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;
- (void)respondToTapGesture:(UITapGestureRecognizer *)tapRecognizer;
- (void)respondToDoubleTapGesture:(UITapGestureRecognizer *)doubleTapRecognizer;
- (void)respondToPanGesture:(UIPanGestureRecognizer *)panRecognizer;
- (void)respondToPinchGesture:(UIPanGestureRecognizer *)pinchRecognizer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    /* Construct Gesture Recognizers */
    //1. Tap
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(respondToTapGesture:)];
    tapRecognizer.numberOfTapsRequired = 1;
    // TODO: Figure a way to have a delay set for it not to tap gesture not to wait long enough for a doubletap gesture to be recognized
    tapRecognizer.delaysTouchesEnded = NO;
    
    //2. DoubleTap
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc]
                                             initWithTarget:self action:@selector(respondToDoubleTapGesture:)];
    doubleTapRecognizer.numberOfTapsRequired = 2;
    // Distanle single tap when double tap occurs
    [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
    //3. Pan
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]
                                            initWithTarget:self action:@selector(respondToPanGesture:)];
    
    //4. Pinch
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(respondToPinchGesture:)];
    
    
    /* Setup gesture recognizers */
    [self.view addGestureRecognizer:tapRecognizer];
    [self.view addGestureRecognizer:doubleTapRecognizer];
    [self.view addGestureRecognizer:panRecognizer];
    [self.view addGestureRecognizer:pinchRecognizer];
    
    [self setupGL];
    
}

- (void)respondToTapGesture:(UITapGestureRecognizer *)tapRecognizer {
    // Get the location of the tap
    CGPoint location = [tapRecognizer locationInView:self.view];
    CGPoint viewCenter = tapRecognizer.view.center;
    logMsg("%f,%f\n", viewCenter.x, viewCenter.y);
    Tangram::handleTapGesture(location.x - viewCenter.x, -(location.y - viewCenter.y));
}

- (void)respondToDoubleTapGesture:(UITapGestureRecognizer *)doubleTapRecognizer {
    //Get the location of the double tap
    CGPoint location = [doubleTapRecognizer locationInView:self.view];
    Tangram::handleDoubleTapGesture(location.x, location.y);
}

- (void)respondToPanGesture:(UIPanGestureRecognizer *)panRecognizer {
    //velocity is relative to previous drag location
    //not using drag position as its always relative to the initial touch point
    CGPoint velocity = [panRecognizer velocityInView:self.view];
    Tangram::handlePanGesture(velocity.x, velocity.y);
}

- (void)respondToPinchGesture:(UIPinchGestureRecognizer *)pinchRecognizer {
    CGPoint location = [pinchRecognizer locationInView:self.view];
    CGFloat scale = pinchRecognizer.scale;
    //Do discrete zoom (only handle the pinch gesture, when it ends
    //TODO: continous zoom
    if(pinchRecognizer.state == UIGestureRecognizerStateEnded) {
        Tangram::handlePinchGesture(location.x, location.y, scale);
    }
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    Tangram::initialize();
    
    int width = self.view.bounds.size.width;
    int height = self.view.bounds.size.height;
    Tangram::resize(width, height);
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    Tangram::teardown();
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    Tangram::update([self timeSinceLastUpdate]);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    Tangram::render();
}

@end
