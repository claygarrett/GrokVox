//
//  MetalView.h
//  GrokVox
//
//  Created by Clay Garrett on 11/8/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>

#import "MetalView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GVMetalViewDelegate;



@interface MetalView : UIView

/// The delegate of this view, responsible for drawing
@property (nonatomic, weak) id<GVMetalViewDelegate> delegate;

/// A getter for the later, cast as a metal layer
@property (readonly) CAMetalLayer *metalLayer;

- (void)setFrame:(CGRect)frame;

/// The duration (in seconds) of the previous frame. This is valid only in the context
/// of a callback to the delegate's -viewIsReadyToDraw: method.
@property (nonatomic, readonly) NSTimeInterval frameDuration;

/// A render pass descriptor configured to use the current drawable's texture
/// as its primary color attachment and an internal depth texture of the same
/// size as its depth attachment's texture
- (MTLRenderPassDescriptor *)currentRenderPassDescriptor;

/// The view's layer's current drawable. This is valid only in the context
/// of a callback to the delegate's -viewIsReadyToDraw: method.
@property (nonatomic, readonly) id<CAMetalDrawable> drawable;


@end

@protocol GVMetalViewDelegate <NSObject>
/// This method is called once per frame. Within the method, you may access
/// any of the properties of the view, and request the current render pass
/// descriptor to get a descriptor configured with renderable color and depth
/// textures.
- (void)viewIsReadyToDraw:(MetalView *)view;
@end


NS_ASSUME_NONNULL_END
