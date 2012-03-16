#import "Code128Reader.h"
#import "Code128Writer.h"

int const CODE_START_B = 104;
int const CODE_START_C = 105;
int const CODE_CODE_B = 100;
int const CODE_CODE_C = 99;
int const CODE_STOP = 106;

@interface Code128Writer ()

- (BOOL) isDigits:(NSString *)value start:(int)start length:(int)length;

@end

@implementation Code128Writer

- (BitMatrix *) encode:(NSString *)contents format:(BarcodeFormat)format width:(int)width height:(int)height hints:(NSMutableDictionary *)hints {
  if (format != kBarcodeFormatCode128) {
    [NSException raise:NSInvalidArgumentException format:@"Can only encode CODE_128"];
  }
  return [super encode:contents format:format width:width height:height hints:hints];
}

- (NSArray *) encode:(NSString *)contents {
  int length = [contents length];
  if (length < 1 || length > 80) {
    [NSException raise:NSInvalidArgumentException format:@"Contents length should be between 1 and 80 characters, but got %d", length];
  }

  for (int i = 0; i < length; i++) {
    unichar c = [contents characterAtIndex:i];
    if (c < ' ' || c > '~') {
      [NSException raise:NSInvalidArgumentException format:@"Contents should only contain characters between ' ' and '~'"];
    }
  }

  NSMutableArray * patterns = [NSMutableArray array];
  int checkSum = 0;
  int checkWeight = 1;
  int codeSet = 0;
  int position = 0;

  while (position < length) {
    int requiredDigitCount = codeSet == CODE_CODE_C ? 2 : 4;
    int newCodeSet;
    if (length - position >= requiredDigitCount && [self isDigits:contents start:position length:requiredDigitCount]) {
      newCodeSet = CODE_CODE_C;
    } else {
      newCodeSet = CODE_CODE_B;
    }

    int patternIndex;
    if (newCodeSet == codeSet) {
      if (codeSet == CODE_CODE_B) {
        patternIndex = [contents characterAtIndex:position] - ' ';
        position += 1;
      } else {
        patternIndex = [[contents substringWithRange:NSMakeRange(position, 2)] intValue];
        position += 2;
      }
    } else {
      if (codeSet == 0) {
        if (newCodeSet == CODE_CODE_B) {
          patternIndex = CODE_START_B;
        } else {
          patternIndex = CODE_START_C;
        }
      } else {
        patternIndex = newCodeSet;
      }
      codeSet = newCodeSet;
    }

    NSMutableArray *pattern = [NSMutableArray array];
    for (int i = 0; i < sizeof(CODE_PATTERNS[patternIndex]) / sizeof(int); i++) {
      [pattern addObject:[NSNumber numberWithInt:CODE_PATTERNS[patternIndex][i]]];
    }
    [patterns addObject:pattern];

    checkSum += patternIndex * checkWeight;
    if (position != 0) {
      checkWeight++;
    }
  }

  checkSum %= 103;
  NSMutableArray *pattern = [NSMutableArray array];
  for (int i = 0; i < sizeof(CODE_PATTERNS[checkSum]) / sizeof(int); i++) {
    [pattern addObject:[NSNumber numberWithInt:CODE_PATTERNS[checkSum][i]]];
  }
  [patterns addObject:pattern];

  pattern = [NSMutableArray array];
  for (int i = 0; i < sizeof(CODE_PATTERNS[CODE_STOP]) / sizeof(int); i++) {
    [pattern addObject:[NSNumber numberWithInt:CODE_PATTERNS[CODE_STOP][i]]];
  }
  [patterns addObject:pattern];

  NSMutableArray *result = [NSMutableArray array];
  int pos = 0;
  for (NSArray *patternArray in patterns) {
    int pattern[[patternArray count]];
    for(int i = 0; i < [patternArray count]; i++) {
      pattern[i] = [[patternArray objectAtIndex:i] intValue];
    }

    pos += [UPCEANWriter appendPattern:result pos:pos pattern:pattern startColor:1];
  }

  return result;
}

- (BOOL) isDigits:(NSString *)value start:(int)start length:(int)length {
  int end = start + length;

  for (int i = start; i < end; i++) {
    unichar c = [value characterAtIndex:i];
    if (c < '0' || c > '9') {
      return NO;
    }
  }

  return YES;
}

@end
