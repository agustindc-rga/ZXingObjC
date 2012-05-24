#import "ZXBarcodeFormat.h"
#import "ZXEAN8Writer.h"
#import "ZXUPCEANReader.h"

int const EAN8codeWidth = 3 + (7 * 4) + 5 + (7 * 4) + 3;

@implementation ZXEAN8Writer

- (ZXBitMatrix *)encode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height hints:(ZXEncodeHints *)hints error:(NSError **)error {
  if (format != kBarcodeFormatEan8) {
    [NSException raise:NSInvalidArgumentException format:@"Can only encode EAN_8"];
  }
  return [super encode:contents format:format width:width height:height hints:hints error:error];
}


/**
 * Returns a byte array of horizontal pixels (0 = white, 1 = black)
 */
- (NSArray *)encode:(NSString *)contents {
  if ([contents length] != 8) {
    [NSException raise:NSInvalidArgumentException format:@"Requested contents should be 8 digits long, but got %d", [contents length]];
  }

  NSMutableArray * result = [NSMutableArray arrayWithCapacity:EAN8codeWidth];
  for (int i = 0; i < EAN8codeWidth; i++) {
    [result addObject:[NSNumber numberWithInt:0]];
  }
  int pos = 0;

  pos += [ZXUPCEANWriter appendPattern:result pos:pos pattern:(int*)START_END_PATTERN patternLen:START_END_PATTERN_LEN startColor:1];

  for (int i = 0; i <= 3; i++) {
    int digit = [[contents substringWithRange:NSMakeRange(i, 1)] intValue];
    pos += [ZXUPCEANWriter appendPattern:result pos:pos pattern:(int*)L_PATTERNS[digit] patternLen:L_PATTERNS_SUB_LEN startColor:0];
  }

  pos += [ZXUPCEANWriter appendPattern:result pos:pos pattern:(int*)MIDDLE_PATTERN patternLen:MIDDLE_PATTERN_LEN startColor:0];

  for (int i = 4; i <= 7; i++) {
    int digit = [[contents substringWithRange:NSMakeRange(i, 1)] intValue];
    pos += [ZXUPCEANWriter appendPattern:result pos:pos pattern:(int*)L_PATTERNS[digit] patternLen:L_PATTERNS_SUB_LEN startColor:1];
  }

  pos += [ZXUPCEANWriter appendPattern:result pos:pos pattern:(int*)START_END_PATTERN patternLen:START_END_PATTERN_LEN startColor:1];

  return result;
}

@end
