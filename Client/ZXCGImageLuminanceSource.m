// -*- mode:objc; c-basic-offset:2; indent-tabs-mode:nil -*-
/*
 * Copyright 2011 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "ZXCGImageLuminanceSource.h"
#import "ZXImage.h"

@interface ZXCGImageLuminanceSource ()

- (void)initializeWithImage:(CGImageRef)image left:(int)left top:(int)top width:(int)width height:(int)height;

@end

@implementation ZXCGImageLuminanceSource

+ (CGImageRef)createImageFromBuffer:(CVImageBufferRef)buffer {
  return [self createImageFromBuffer:buffer
                                left:0
                                 top:0
                               width:CVPixelBufferGetWidth(buffer)
                              height:CVPixelBufferGetHeight(buffer)];
}

+ (CGImageRef)createImageFromBuffer:(CVImageBufferRef)buffer
                                      left:(size_t)left
                                       top:(size_t)top
                                     width:(size_t)width
                                    height:(size_t)height {
  int bytesPerRow = CVPixelBufferGetBytesPerRow(buffer); 
  int dataWidth = CVPixelBufferGetWidth(buffer); 
  int dataHeight = CVPixelBufferGetHeight(buffer); 

  if (left + width > dataWidth ||
      top + height > dataHeight) {
    [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
  }

  int newBytesPerRow = ((width*4+0xf)>>4)<<4;

  CVPixelBufferLockBaseAddress(buffer,0); 
  
  unsigned char* baseAddress =
  (unsigned char*)CVPixelBufferGetBaseAddress(buffer); 
  
  int size = newBytesPerRow*height;
  unsigned char* bytes = (unsigned char*)malloc(size);
  if (newBytesPerRow == bytesPerRow) {
    memcpy(bytes, baseAddress+top*bytesPerRow, size);
  } else {
    for(int y=0; y<height; y++) {
      memcpy(bytes+y*bytesPerRow,
             baseAddress+left*4+(top+y)*bytesPerRow,
             bytesPerRow);
    }
  }
  CVPixelBufferUnlockBaseAddress(buffer, 0);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
  CGContextRef newContext = CGBitmapContextCreate(bytes,
                                                  width,
                                                  height,
                                                  8,
                                                  newBytesPerRow,
                                                  colorSpace,
                                                  kCGBitmapByteOrder32Little|
                                                  kCGImageAlphaNoneSkipFirst);
  CGColorSpaceRelease(colorSpace);
  
  CGImageRef result = CGBitmapContextCreateImage(newContext); 
  
  CGContextRelease(newContext); 
  
  free(bytes);
  
  return result;

}

- (ZXCGImageLuminanceSource*)initWithZXImage:(ZXImage*)_image 
                                      left:(size_t)_left
                                       top:(size_t)_top
                                     width:(size_t)_width
                                    height:(size_t)_height {
  self = [self initWithCGImage:_image.cgimage left:_left top:_top width:_width height:_height];

  return self;
}

- (ZXCGImageLuminanceSource*)initWithZXImage:(ZXImage*)_image {
  self = [self initWithCGImage:_image.cgimage];

  return self;
}

- (ZXCGImageLuminanceSource*)initWithCGImage:(CGImageRef)_image 
                                      left:(size_t)_left
                                       top:(size_t)_top
                                     width:(size_t)_width
                                    height:(size_t)_height {
  self = [super init];

  if (self) {
    [self initializeWithImage:_image left:_left top:_top width:_width height:_height];
  }

  return self;
}

- (ZXCGImageLuminanceSource*)initWithCGImage:(CGImageRef)_image {
  self = [self initWithCGImage:_image left:0 top:0 width:CGImageGetWidth(_image) height:CGImageGetHeight(_image)];

  return self;
}

- (ZXCGImageLuminanceSource*)initWithBuffer:(CVPixelBufferRef)buffer
                                      left:(size_t)_left
                                       top:(size_t)_top
                                     width:(size_t)_width
                                    height:(size_t)_height {
  CGImageRef _image = [ZXCGImageLuminanceSource createImageFromBuffer:buffer left:_left top:_top width:_width height:_height];
  
  self = [self initWithCGImage:_image];
  
  CGImageRelease(image);
  
  return self;
}

- (ZXCGImageLuminanceSource*)initWithBuffer:(CVPixelBufferRef)buffer {
  CGImageRef _image = [ZXCGImageLuminanceSource createImageFromBuffer:buffer];

  self = [self initWithCGImage:_image];

  CGImageRelease(image);

  return self;
}

- (CGImageRef)image {
  return image;
}

- (void)dealloc {  
  if (image) {
    CGImageRelease(image);
  }
  if (data) {
    CFRelease(data);
  }

  [super dealloc];
}

- (unsigned char *) getRow:(int)y row:(unsigned char *)row {
  if (y < 0 || y >= self.height) {
    [NSException raise:NSInvalidArgumentException format:@"Requested row is outside the image: %d", y];
  }

  if (row == NULL) {
    row = (unsigned char*)malloc(width * sizeof(unsigned char));
  }

  int offset = (y + top) * dataWidth + left;
  CFDataGetBytes(data, CFRangeMake(offset, width), row);

  return row;
}

- (unsigned char*) matrix {
  int size = width * height;
  unsigned char* result = (unsigned char*)malloc(size * sizeof(unsigned char));
  if (left == 0 && top == 0 && dataWidth == width && dataHeight == height) {
    CFDataGetBytes(data, CFRangeMake(0, size), result);
  } else {
    for (int row = 0; row < height; row++) {
      CFDataGetBytes(data,
                     CFRangeMake((top + row) * dataWidth + left, width),
                     result + row * width);
    }
  }
  return result;
}

- (void)initializeWithImage:(CGImageRef)cgimage left:(int)_left top:(int)_top width:(int)_width height:(int)_height {
  data = 0;
  image = cgimage;
  left = _left;
  top = _top;
  width = _width;
  height = _height;
  dataWidth = CGImageGetWidth(cgimage);
  dataHeight = CGImageGetHeight(cgimage);
  
  if (left + width > dataWidth ||
      top + height > dataHeight ||
      top < 0 ||
      left < 0) {
    [NSException raise:NSInvalidArgumentException format:@"Crop rectangle does not fit within image data."];
  }
  
  CGColorSpaceRef space = CGImageGetColorSpace(image);
  CGColorSpaceModel model = CGColorSpaceGetModel(space);
  
  if (model != kCGColorSpaceModelMonochrome ||
      CGImageGetBitsPerComponent(image) != 8 ||
      CGImageGetBitsPerPixel(image) != 8) {
    
    CGColorSpaceRef gray = CGColorSpaceCreateDeviceGray();
    
    CGContextRef ctx = CGBitmapContextCreate(0,
                                             width,
                                             height, 
                                             8,
                                             width,
                                             gray, 
                                             kCGImageAlphaNone);
    
    CGColorSpaceRelease(gray);
    
    if (top || left) {
      CGContextClipToRect(ctx, CGRectMake(0, 0, width, height));
    }
    
    CGContextDrawImage(ctx, CGRectMake(-left, -top, width, height), image);
    
    image = CGBitmapContextCreateImage(ctx); 
    
    bytesPerRow = width;
    top = 0;
    left = 0;
    dataWidth = width;
    dataHeight = height;
    
    CGContextRelease(ctx);
  } else {
    CGImageRetain(image);
  }
  
  CGDataProviderRef provider = CGImageGetDataProvider(image);
  data = CGDataProviderCopyData(provider);
}


@end
