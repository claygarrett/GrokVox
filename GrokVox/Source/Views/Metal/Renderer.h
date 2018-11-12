//
//  Renderer.h
//  GrokVox
//
//  Created by Clay Garrett on 11/11/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalView.h"

NS_ASSUME_NONNULL_BEGIN

@interface Renderer : NSObject<GVMetalViewDelegate>

-(id)initWithView:(MetalView *)view;

@end

NS_ASSUME_NONNULL_END
