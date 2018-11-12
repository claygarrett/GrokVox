//
//  ViewController.m
//  GrokVox
//
//  Created by Clay Garrett on 11/8/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#import "ViewController.h"
#import "MetalView.h"
#import "Renderer.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet MetalView *metalView;
@property (nonatomic, strong) Renderer *renderer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.renderer = [[Renderer alloc] initWithView:self.view];
    self.metalView.delegate = self.renderer;
}

- (void)viewDidLayoutSubviews {
    [_metalView setFrame:self.view.frame];
}


@end
