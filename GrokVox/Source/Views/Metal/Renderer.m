//
//  Renderer.m
//  GrokVox
//
//  Created by Clay Garrett on 11/11/18.
//  Copyright © 2018 Clay Garrett. All rights reserved.
//

#import "Renderer.h"
#import "MetalView.h"
#import "MathUtiltites.h"

@import simd;
@import Metal;


@implementation Renderer

typedef struct {
    vector_float4 position;
    vector_float4 color;
} GVVertex;

typedef struct {
    matrix_float4x4 modelViewProjectionMatrix;
} GVUniforms;

typedef uint16_t GVIndex;
const MTLIndexType GVIndexType = MTLIndexTypeUInt16;


id<MTLDevice> metalDevice;
id<MTLBuffer> vertexBuffer;
id<MTLBuffer> indexBuffer;
id<MTLBuffer> uniformBuffer;
id<MTLCommandQueue> commandQueue;
id<MTLRenderPipelineState> pipeline;
id<MTLDepthStencilState> depthStencilState;

dispatch_semaphore_t displaySemaphore;
static const NSInteger GVInFlightBufferCount = 3;
NSInteger bufferIndex;

MetalView *metalView;

float rotationX, rotationY, rotationZ, timePassed;


-(id)initWithView:(MetalView *)view {
    self = [super init];
    if(self) {
        metalView = view;
        [self makeDevice];
        [self makeBuffers];
        [self makePipeline];
        
        displaySemaphore = dispatch_semaphore_create(GVInFlightBufferCount);
    }
    return self;
}

-(void) makeDevice {
    metalDevice = MTLCreateSystemDefaultDevice();
}

/**
 Create the pipeline state to be used in rendering
 */
-(void) makePipeline {
    
    // get a new command queue from the device.
    // a command queue keeps a list of command buffers to be executed
    commandQueue = [metalDevice newCommandQueue];
    
    id<MTLLibrary> library = [metalDevice newDefaultLibrary];
    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_project"];
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_flatcolor"];
    
    MTLRenderPipelineDescriptor *pipelineDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineDescriptor.vertexFunction = vertexFunc;
    pipelineDescriptor.fragmentFunction = fragmentFunc;
    pipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
    
    pipeline = [metalDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [MTLDepthStencilDescriptor new];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;
    depthStencilState = [metalDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
}

/**
 Create our initial vertex, index, and uniform buffers
 */
-(void) makeBuffers {
    
    // we create a diff color for each side of our triangel
    static const simd_float4 color1 = { 0.972, 0.588, 0.686, 1};
    static const simd_float4 color2 = { 0.972, 0.607, 0.603, 1};
    static const simd_float4 color3 = { 0.988, 0.807, 0.686, 1};
    static const simd_float4 color4 = { 0.780, 0.784, 0.670, 1};
    static const simd_float4 color5 = { 0.517, 0.686, 0.615, 1};
    static const simd_float4 color6 = { 0.494, 0.650, 0.686, 1};
    
    // define our verts. 2 tris per square
    static const GVVertex vertices[] =
    {
        // side 1
        { .position = { -1.0f,-1.0f,-1.0f, 1 }, .color = color1 },
        { .position = { -1.0f,-1.0f, 1.0f, 1 }, .color = color1 },
        { .position = { -1.0f, 1.0f, 1.0f, 1 }, .color = color1 },
        { .position = { -1.0f,-1.0f,-1.0f, 1 }, .color = color1 },
        { .position = { -1.0f, 1.0f, 1.0f, 1 }, .color = color1 },
        { .position = { -1.0f, 1.0f,-1.0f, 1 }, .color = color1 },
        
        // side 2
        { .position = { 1.0f, 1.0f,-1.0f, 1 }, .color = color2 },
        { .position = { -1.0f,-1.0f,-1.0f, 1 }, .color = color2 },
        { .position = { -1.0f, 1.0f,-1.0f, 1 }, .color = color2 },
        { .position = { 1.0f, 1.0f,-1.0f, 1 }, .color = color2 },
        { .position = { 1.0f,-1.0f,-1.0f, 1 }, .color = color2 },
        { .position = { -1.0f,-1.0f,-1.0f, 1 }, .color = color2 },
        
        // side 3
        { .position = { 1.0f,-1.0f, 1.0f, 1 }, .color = color3 },
        { .position = { -1.0f,-1.0f,-1.0f, 1 }, .color = color3 },
        { .position = { 1.0f,-1.0f,-1.0f, 1 }, .color = color3 },
        { .position = { 1.0f,-1.0f, 1.0f, 1 }, .color = color3 },
        { .position = { -1.0f,-1.0f, 1.0f, 1 }, .color = color3 },
        { .position = { -1.0f,-1.0f,-1.0f, 1 }, .color = color3 },
        
        // side 4
        { .position = { -1.0f, 1.0f, 1.0f, 1 }, .color = color4 },
        { .position = { -1.0f,-1.0f, 1.0f, 1 }, .color = color4 },
        { .position = { 1.0f,-1.0f, 1.0f, 1 }, .color = color4 },
        { .position = { 1.0f, 1.0f, 1.0f, 1 }, .color = color4 },
        { .position = { -1.0f, 1.0f, 1.0f, 1 }, .color = color4 },
        { .position = { 1.0f,-1.0f, 1.0f, 1 }, .color = color4 },
        
        // side 5
        { .position = { 1.0f, 1.0f, 1.0f, 1 }, .color = color5 },
        { .position = { 1.0f,-1.0f,-1.0f, 1 }, .color = color5 },
        { .position = { 1.0f, 1.0f,-1.0f, 1 }, .color = color5 },
        { .position = { 1.0f,-1.0f,-1.0f, 1 }, .color = color5 },
        { .position = { 1.0f, 1.0f, 1.0f, 1 }, .color = color5 },
        { .position = { 1.0f,-1.0f, 1.0f, 1 }, .color = color5 },
        
        // side 6
        { .position = { 1.0f, 1.0f, 1.0f, 1 }, .color = color6 },
        { .position = { 1.0f, 1.0f,-1.0f, 1 }, .color = color6 },
        { .position = { -1.0f, 1.0f,-1.0f, 1 }, .color = color6 },
        { .position = { 1.0f, 1.0f, 1.0f, 1 }, .color = color6 },
        { .position = { -1.0f, 1.0f,-1.0f, 1 }, .color = color6 },
        { .position = { -1.0f, 1.0f, 1.0f, 1 }, .color = color6 }
    };
    
    // create the vert buffer
    vertexBuffer = [metalDevice newBufferWithBytes:vertices length:sizeof(vertices) options:MTLResourceOptionCPUCacheModeDefault];
    [vertexBuffer setLabel:@"Vertices"];
    
    // create the index buffer
    const GVIndex indices[] = {
        0, 1, 2,
        3, 4, 5,
        6, 7, 8,
        9, 10, 11,
        12, 13, 14,
        15, 16, 17,
        18, 19, 20,
        21, 22, 23,
        24, 25, 26,
        27, 28, 29,
        30, 31, 32,
        33, 34, 35
    };
    
    indexBuffer = [metalDevice newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceOptionCPUCacheModeDefault];
    [indexBuffer setLabel:@"Indices"];
    
    // create the uniform buffer
    uniformBuffer = [metalDevice newBufferWithLength:sizeof(GVUniforms) * GVInFlightBufferCount
                                              options:MTLResourceOptionCPUCacheModeDefault];
    [uniformBuffer setLabel:@"Uniforms"];
}

/**
 Updates the uniform buffer with the latest transformation data

 @param view The view we're updating the buffer for. It has the size information we need for our projection matrix
 @param duration The amount of time passed since the last draw
 */
- (void)updateUniformsForView:(MetalView *)view duration:(NSTimeInterval)duration {
    // update our time passed, rotation and scale values
    timePassed += duration;
    rotationX += duration * (M_PI / 2);
    rotationY += duration * (M_PI / 3);
    rotationZ += duration * (M_PI / 4);
    float scaleFactor = sinf(5 * timePassed) * 0.25 + 1;
    
    // rotate around the 3 diff axes
    const vector_float3 xAxis = { 1, 0, 0};
    const vector_float3 yAxis = { 0, 1, 0};
    const vector_float3 zAxis = { 0, 0, 1};
    
    const matrix_float4x4 xRot = matrix_float4x4_rotation(xAxis, rotationX);
    const matrix_float4x4 yRot = matrix_float4x4_rotation(yAxis, rotationY);
    const matrix_float4x4 zRot = matrix_float4x4_rotation(zAxis, rotationZ);
    
    // scale based on time
    matrix_float4x4 scale = matrix_float4x4_uniform_scale(scaleFactor);
    matrix_float4x4 modelMatrix = matrix_multiply(matrix_multiply(xRot, matrix_multiply(yRot, zRot)), scale);
    
    // calculate our view matrix
    const vector_float3 cameraTranslation = { 0, 0, -5 };
    const matrix_float4x4 viewMatrix = matrix_float4x4_translation(cameraTranslation);
    
    // calculate our projection matrix
    const CGSize drawableSize = view.metalLayer.drawableSize;
    const float aspect = drawableSize.width / drawableSize.height;
    const float fov = (2 * M_PI) / 5;
    const float near = 1;
    const float far = 100;
    const matrix_float4x4 projectionMatrix = matrix_float4x4_perspective(aspect, fov, near, far);
    
    // calculate our MVP matrix
    GVUniforms uniforms;
    uniforms.modelViewProjectionMatrix = matrix_multiply(projectionMatrix, matrix_multiply(viewMatrix, modelMatrix));
    
    // copy the data to the new buffer
    const NSUInteger uniformBufferOffset = sizeof(GVUniforms) * bufferIndex;
    memcpy([uniformBuffer contents] + uniformBufferOffset, &uniforms, sizeof(uniforms));
    
}

/**
 Signals that the view is ready for drawing

 @param view The view that should be drawn on
 */
- (void)viewIsReadyToDraw:(MetalView *)view {
    
    dispatch_semaphore_wait(displaySemaphore, DISPATCH_TIME_FOREVER);
    
    // get a drawable, which contains a 2D texture the size of the view
    [self updateUniformsForView:view duration:view.frameDuration];
    
    // a command buffer is a collection of render commands, all executed together
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    // command encoders define the nitty gritty of what we're going to draw
    // takes high level commands such as shader params, triangles, etc into low level instructions
    id <MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:[view currentRenderPassDescriptor]];
    
    // the encoder needs a pipeline state. pass the one we created earlier
    [commandEncoder setRenderPipelineState:pipeline];
    
    // we're using multiple uniform buffers for better parallelization
    // set the offset to the current one
    const NSUInteger uniformBufferOffset = sizeof(GVUniforms) * bufferIndex;
    
    // upload the vertex/uniform buffers buffers
    [commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [commandEncoder setVertexBuffer:uniformBuffer offset:uniformBufferOffset atIndex:1];

    // set a few properties on the encoder
    [commandEncoder setDepthStencilState:depthStencilState];
    [commandEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [commandEncoder setCullMode:MTLCullModeBack];

    // draw the primitives with our index buffer
    [commandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:indexBuffer.length / sizeof(GVIndex) indexType:GVIndexType indexBuffer:indexBuffer indexBufferOffset:0];

    // encode our commands
    [commandEncoder endEncoding];

    // give the command buffer a reference to the drawable it should use
    [commandBuffer presentDrawable:view.drawable];

    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer) {
    bufferIndex = (bufferIndex + 1) % GVInFlightBufferCount;
    dispatch_semaphore_signal(displaySemaphore);
    }];

    // do the thang
    [commandBuffer commit];
}

@end
