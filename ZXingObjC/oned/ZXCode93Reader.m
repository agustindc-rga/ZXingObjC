#import "ZXBitArray.h"
#import "ZXChecksumException.h"
#import "ZXCode93Reader.h"
#import "ZXFormatException.h"
#import "ZXNotFoundException.h"
#import "ZXResult.h"
#import "ZXResultPoint.h"

const NSString *CODE93_ALPHABET_STRING = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%abcd*";
const char CODE93_ALPHABET[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. $/+%abcd*";

/**
 * These represent the encodings of characters, as patterns of wide and narrow bars.
 * The 9 least-significant bits of each int correspond to the pattern of wide and narrow.
 */
const int CODE93_CHARACTER_ENCODINGS[48] = {
  0x114, 0x148, 0x144, 0x142, 0x128, 0x124, 0x122, 0x150, 0x112, 0x10A, // 0-9
  0x1A8, 0x1A4, 0x1A2, 0x194, 0x192, 0x18A, 0x168, 0x164, 0x162, 0x134, // A-J
  0x11A, 0x158, 0x14C, 0x146, 0x12C, 0x116, 0x1B4, 0x1B2, 0x1AC, 0x1A6, // K-T
  0x196, 0x19A, 0x16C, 0x166, 0x136, 0x13A, // U-Z
  0x12E, 0x1D4, 0x1D2, 0x1CA, 0x16E, 0x176, 0x1AE, // - - %
  0x126, 0x1DA, 0x1D6, 0x132, 0x15E, // Control chars? $-*
};

const int CODE93_ASTERISK_ENCODING = 0x15E;

@interface ZXCode93Reader ()

- (void) checkChecksums:(NSMutableString *)result;
- (void) checkOneChecksum:(NSMutableString *)result checkPosition:(int)checkPosition weightMax:(int)weightMax;
- (NSString *) decodeExtended:(NSMutableString *)encoded;
- (NSArray *) findAsteriskPattern:(ZXBitArray *)row;
- (unichar) patternToChar:(int)pattern;
- (int) toPattern:(int[])counters;

@end

@implementation ZXCode93Reader

- (ZXResult *) decodeRow:(int)rowNumber row:(ZXBitArray *)row hints:(NSMutableDictionary *)hints {
  NSArray * start = [self findAsteriskPattern:row];
  int nextStart = [[start objectAtIndex:1] intValue];
  int end = [row size];

  while (nextStart < end && ![row get:nextStart]) {
    nextStart++;
  }

  NSMutableString * result = [NSMutableString stringWithCapacity:20];
  int counters[6];
  unichar decodedChar;
  int lastStart;
  do {
    [ZXOneDReader recordPattern:row start:nextStart counters:counters];
    int pattern = [self toPattern:counters];
    if (pattern < 0) {
      @throw [ZXNotFoundException notFoundInstance];
    }
    decodedChar = [self patternToChar:pattern];
    [result appendFormat:@"%C", decodedChar];
    lastStart = nextStart;
    for (int i = 0; i < sizeof(counters) / sizeof(int); i++) {
      nextStart += counters[i];
    }

    while (nextStart < end && ![row get:nextStart]) {
      nextStart++;
    }
  } while (decodedChar != '*');
  [result deleteCharactersInRange:NSMakeRange([result length] - 1, 1)];

  if (nextStart == end || ![row get:nextStart]) {
    @throw [ZXNotFoundException notFoundInstance];
  }

  if ([result length] < 2) {
    @throw [ZXNotFoundException notFoundInstance];
  }

  [self checkChecksums:result];
  [result deleteCharactersInRange:NSMakeRange([result length] - 2, 2)];

  NSString * resultString = [self decodeExtended:result];

  float left = (float)([[start objectAtIndex:1] intValue] + [[start objectAtIndex:0] intValue]) / 2.0f;
  float right = (float)(nextStart + lastStart) / 2.0f;
  return [[[ZXResult alloc] initWithText:resultString
                              rawBytes:nil
                                length:0
                          resultPoints:[NSArray arrayWithObjects:[[[ZXResultPoint alloc] initWithX:left y:(float)rowNumber] autorelease], [[[ZXResultPoint alloc] initWithX:right y:(float)rowNumber] autorelease], nil]
                                format:kBarcodeFormatCode93] autorelease];
}

- (NSArray *) findAsteriskPattern:(ZXBitArray *)row {
  int width = [row size];
  int rowOffset = 0;
  while (rowOffset < width) {
    if ([row get:rowOffset]) {
      break;
    }
    rowOffset++;
  }

  int counterPosition = 0;
  int counters[6];
  int patternStart = rowOffset;
  BOOL isWhite = NO;
  int patternLength = sizeof(counters) / sizeof(int);

  for (int i = rowOffset; i < width; i++) {
    BOOL pixel = [row get:i];
    if (pixel ^ isWhite) {
      counters[counterPosition]++;
    }
     else {
      if (counterPosition == patternLength - 1) {
        if ([self toPattern:counters] == CODE93_ASTERISK_ENCODING) {
          return [NSArray arrayWithObjects:[NSNumber numberWithInt:patternStart], [NSNumber numberWithInt:i], nil];
        }
        patternStart += counters[0] + counters[1];
        for (int y = 2; y < patternLength; y++) {
          counters[y - 2] = counters[y];
        }
        counters[patternLength - 2] = 0;
        counters[patternLength - 1] = 0;
        counterPosition--;
      } else {
        counterPosition++;
      }
      counters[counterPosition] = 1;
      isWhite = !isWhite;
    }
  }

  @throw [ZXNotFoundException notFoundInstance];
}

- (int) toPattern:(int[])counters {
  int max = sizeof((int*)counters) / sizeof(int);
  int sum = 0;
  for (int i = 0; i < max; i++) {
    sum += counters[i];
  }
  int pattern = 0;
  for (int i = 0; i < max; i++) {
    int scaledShifted = (counters[i] << INTEGER_MATH_SHIFT) * 9 / sum;
    int scaledUnshifted = scaledShifted >> INTEGER_MATH_SHIFT;
    if ((scaledShifted & 0xFF) > 0x7F) {
      scaledUnshifted++;
    }
    if (scaledUnshifted < 1 || scaledUnshifted > 4) {
      return -1;
    }
    if ((i & 0x01) == 0) {
      for (int j = 0; j < scaledUnshifted; j++) {
        pattern = (pattern << 1) | 0x01;
      }
    } else {
      pattern <<= scaledUnshifted;
    }
  }
  return pattern;
}

- (unichar) patternToChar:(int)pattern {
  for (int i = 0; i < sizeof(CODE93_CHARACTER_ENCODINGS) / sizeof(int); i++) {
    if (CODE93_CHARACTER_ENCODINGS[i] == pattern) {
      return CODE93_ALPHABET[i];
    }
  }

  @throw [ZXNotFoundException notFoundInstance];
}

- (NSString *) decodeExtended:(NSMutableString *)encoded {
  int length = [encoded length];
  NSMutableString * decoded = [NSMutableString stringWithCapacity:length];
  for (int i = 0; i < length; i++) {
    unichar c = [encoded characterAtIndex:i];
    if (c >= 'a' && c <= 'd') {
      unichar next = [encoded characterAtIndex:i + 1];
      unichar decodedChar = '\0';
      switch (c) {
      case 'd':
        if (next >= 'A' && next <= 'Z') {
          decodedChar = (unichar)(next + 32);
        } else {
          @throw [ZXFormatException formatInstance];
        }
        break;
      case 'a':
        if (next >= 'A' && next <= 'Z') {
          decodedChar = (unichar)(next - 64);
        } else {
          @throw [ZXFormatException formatInstance];
        }
        break;
      case 'b':
        if (next >= 'A' && next <= 'E') {
          decodedChar = (unichar)(next - 38);
        } else if (next >= 'F' && next <= 'W') {
          decodedChar = (unichar)(next - 11);
        } else {
          @throw [ZXFormatException formatInstance];
        }
        break;
      case 'c':
        if (next >= 'A' && next <= 'O') {
          decodedChar = (unichar)(next - 32);
        } else if (next == 'Z') {
          decodedChar = ':';
        } else {
          @throw [ZXFormatException formatInstance];
        }
        break;
      }
      [decoded appendFormat:@"%C", decodedChar];
      i++;
    } else {
      [decoded appendFormat:@"%C", c];
    }
  }

  return decoded;
}

- (void) checkChecksums:(NSMutableString *)result {
  int length = [result length];
  [self checkOneChecksum:result checkPosition:length - 2 weightMax:20];
  [self checkOneChecksum:result checkPosition:length - 1 weightMax:15];
}

- (void) checkOneChecksum:(NSMutableString *)result checkPosition:(int)checkPosition weightMax:(int)weightMax {
  int weight = 1;
  int total = 0;

  for (int i = checkPosition - 1; i >= 0; i--) {
    total += weight * [CODE93_ALPHABET_STRING rangeOfString:[NSString stringWithFormat:@"%C", [result characterAtIndex:i]]].location;
    if (++weight > weightMax) {
      weight = 1;
    }
  }

  if ([result characterAtIndex:checkPosition] != CODE93_ALPHABET[total % 47]) {
    @throw [ZXChecksumException checksumInstance];
  }
}

@end
