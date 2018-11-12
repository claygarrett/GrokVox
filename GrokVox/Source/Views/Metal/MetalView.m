//
//  MetalView.m
//  GrokVox
//
//  Created by Clay Garrett on 11/8/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#import "MetalView.h"

@import Metal;
@import simd;


@implementation MetalView


id<MTLTexture> depthTexture;
CADisplayLink *displayLink;


NSInteger preferredFramesPerSecond;


+(id)layerClass {
    return [CAMetalLayer class];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _metalLayer = (CAMetalLayer *)[self layer];
        preferredFramesPerSecond = 60;
        
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    // During the first layout pass, we will not be in a view hierarchy, so we guess our scale
    CGFloat scale = [UIScreen mainScreen].scale;
    
    // If we've moved to a window by the time our frame is being set, we can take its scale as our own
    if (self.window)
    {
        scale = self.window.screen.scale;
    }
    
    CGSize drawableSize = self.bounds.size;
    
    // Since drawable size is in pixels, we need to multiply by the scale to move from points to pixels
    drawableSize.width *= scale;
    drawableSize.height *= scale;
    
    self.metalLayer.drawableSize = drawableSize;
    
    [self makeDepthTexture];
}

- (void)makeDepthTexture
{
    CGSize drawableSize = self.metalLayer.drawableSize;
    
    if ([depthTexture width] != drawableSize.width || [depthTexture height] != drawableSize.height) {
        MTLTextureDescriptor *desc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float
                                                                                        width:drawableSize.width
                                                                                       height:drawableSize.height
                                                                                    mipmapped:NO];
        desc.usage = MTLTextureUsageRenderTarget;
        
        depthTexture = [self.metalLayer.device newTextureWithDescriptor:desc];
    }
}

- (void)didMoveToWindow {
    [super didMoveToSuperview];
    
    const NSTimeInterval idealFrameDuration = (1.0 / 60);
    const NSTimeInterval targetFrameDuration = (1.0 / preferredFramesPerSecond);
    const NSInteger frameInterval = round(targetFrameDuration / idealFrameDuration);

    _metalLayer.device = MTLCreateSystemDefaultDevice();
    
    if(self.window) {
        [displayLink invalidate];
        displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire:)];
        displayLink.frameInterval = frameInterval;
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
    } else {
        [displayLink invalidate];
        displayLink = nil;
    }
}
         
- (void)displayLinkDidFire:(CADisplayLink *)displayLink {
    
    _frameDuration = displayLink.duration;
    _drawable = [self.metalLayer nextDrawable];
    [_delegate viewIsReadyToDraw: self];
}


- (MTLRenderPassDescriptor *)currentRenderPassDescriptor
{
    MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
    
    passDescriptor.colorAttachments[0].texture = [self.drawable texture];
    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.9, 0.9, 0.9, 1);
    passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    passDescriptor.depthAttachment.texture = depthTexture;
    passDescriptor.depthAttachment.clearDepth = 1.0;
    passDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    passDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    return passDescriptor;
}


@end
