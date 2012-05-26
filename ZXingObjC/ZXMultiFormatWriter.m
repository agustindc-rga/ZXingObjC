/*
 * Copyright 2012 ZXing authors
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

#import "ZXBitMatrix.h"
#import "ZXCode39Writer.h"
#import "ZXCode128Writer.h"
#import "ZXEAN8Writer.h"
#import "ZXEAN13Writer.h"
#import "ZXITFWriter.h"
#import "ZXMultiFormatWriter.h"
#import "ZXPDF417Writer.h"
#import "ZXQRCodeWriter.h"
#import "ZXUPCAWriter.h"

@implementation ZXMultiFormatWriter

+ (ZXMultiFormatWriter*)writer {
  return [[[ZXMultiFormatWriter alloc] init] autorelease];
}

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height error:(NSError **)error {
  return [self encode:contents format:format width:width height:height hints:nil error:error];
}

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height hints:(ZXEncodeHints *)hints error:(NSError **)error {
  id<ZXWriter> writer;
  if (format == kBarcodeFormatEan8) {
    writer = [[[ZXEAN8Writer alloc] init] autorelease];
  } else if (format == kBarcodeFormatEan13) {
    writer = [[[ZXEAN13Writer alloc] init] autorelease];
  } else if (format == kBarcodeFormatUPCA) {
    writer = [[[ZXUPCAWriter alloc] init] autorelease];
  } else if (format == kBarcodeFormatQRCode) {
    writer = [[[ZXQRCodeWriter alloc] init] autorelease];
  } else if (format == kBarcodeFormatCode39) {
    writer = [[[ZXCode39Writer alloc] init] autorelease];
  } else if (format == kBarcodeFormatCode128) {
    writer = [[[ZXCode128Writer alloc] init] autorelease];
  } else if (format == kBarcodeFormatITF) {
    writer = [[[ZXITFWriter alloc] init] autorelease];
  } else if (format == kBarcodeFormatPDF417) {
    writer = [[[ZXPDF417Writer alloc] init] autorelease];
  } else {
    [NSException raise:NSInvalidArgumentException 
                format:@"No encoder available for format"];
  }
  return [writer encode:contents format:format width:width height:height hints:hints error:error];
}

@end
