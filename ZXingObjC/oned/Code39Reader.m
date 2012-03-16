#import "ChecksumException.h"
#import "Code39Reader.h"
#import "FormatException.h"
#import "NotFoundException.h"
#import "Result.h"
#import "ResultPoint.h"

const char ALPHABET[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%";
const NSString *ALPHABET_STRING = @"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%";

/**
 * These represent the encodings of characters, as patterns of wide and narrow bars.
 * The 9 least-significant bits of each int correspond to the pattern of wide and narrow,
 * with 1s representing "wide" and 0s representing narrow.
 */
const int CHARACTER_ENCODINGS[44] = {
  0x034, 0x121, 0x061, 0x160, 0x031, 0x130, 0x070, 0x025, 0x124, 0x064, // 0-9
  0x109, 0x049, 0x148, 0x019, 0x118, 0x058, 0x00D, 0x10C, 0x04C, 0x01C, // A-J
  0x103, 0x043, 0x142, 0x013, 0x112, 0x052, 0x007, 0x106, 0x046, 0x016, // K-T
  0x181, 0x0C1, 0x1C0, 0x091, 0x190, 0x0D0, 0x085, 0x184, 0x0C4, 0x094, // U-*
  0x0A8, 0x0A2, 0x08A, 0x02A // $-%
};

int const ASTERISK_ENCODING = 0x094;

@interface Code39Reader ()

- (NSString *) decodeExtended:(NSMutableString *)encoded;
- (NSArray *) findAsteriskPattern:(BitArray *)row;
- (unichar) patternToChar:(int)pattern;
- (int) toNarrowWidePattern:(NSArray *)counters;

@end

@implementation Code39Reader


/**
 * Creates a reader that assumes all encoded data is data, and does not treat the final
 * character as a check digit. It will not decoded "extended Code 39" sequences.
 */
- (id) init {
  return [self initUsingCheckDigit:NO extendedMode:NO];
}


/**
 * Creates a reader that can be configured to check the last character as a check digit.
 * It will not decoded "extended Code 39" sequences.
 * 
 * @param usingCheckDigit if true, treat the last data character as a check digit, not
 * data, and verify that the checksum passes.
 */
- (id) initUsingCheckDigit:(BOOL)isUsingCheckDigit {  
  return [self initUsingCheckDigit:isUsingCheckDigit extendedMode:NO];
}


/**
 * Creates a reader that can be configured to check the last character as a check digit,
 * or optionally attempt to decode "extended Code 39" sequences that are used to encode
 * the full ASCII character set.
 * 
 * @param usingCheckDigit if true, treat the last data character as a check digit, not
 * data, and verify that the checksum passes.
 * @param extendedMode if true, will attempt to decode extended Code 39 sequences in the
 * text.
 */
- (id) initUsingCheckDigit:(BOOL)isUsingCheckDigit extendedMode:(BOOL)isExtendedMode {
  if (self = [super init]) {
    usingCheckDigit = isUsingCheckDigit;
    extendedMode = isExtendedMode;
  }
  return self;
}

- (Result *) decodeRow:(int)rowNumber row:(BitArray *)row hints:(NSMutableDictionary *)hints {
  NSArray * start = [self findAsteriskPattern:row];
  int nextStart = [[start objectAtIndex:1] intValue];
  int end = [row size];

  while (nextStart < end && ![row get:nextStart]) {
    nextStart++;
  }

  NSMutableString *result = [NSMutableString stringWithCapacity:20];
  NSMutableArray * counters = [NSMutableArray arrayWithCapacity:9];
  unichar decodedChar;
  int lastStart;

  do {
    [OneDReader recordPattern:row start:nextStart counters:counters];
    int pattern = [self toNarrowWidePattern:counters];
    if (pattern < 0) {
      @throw [NotFoundException notFoundInstance];
    }
    decodedChar = [self patternToChar:pattern];
    [result appendFormat:@"%c", decodedChar];
    lastStart = nextStart;

    for (int i = 0; i < [counters count]; i++) {
      nextStart += [[counters objectAtIndex:i] intValue];
    }

    while (nextStart < end && ![row get:nextStart]) {
      nextStart++;
    }
  } while (decodedChar != '*');
  [result deleteCharactersInRange:NSMakeRange([result length] - 1, 1)];

  int lastPatternSize = 0;
  for (int i = 0; i < [counters count]; i++) {
    lastPatternSize += [[counters objectAtIndex:i] intValue];
  }
  int whiteSpaceAfterEnd = nextStart - lastStart - lastPatternSize;
  if (nextStart != end && whiteSpaceAfterEnd / 2 < lastPatternSize) {
    @throw [NotFoundException notFoundInstance];
  }

  if (usingCheckDigit) {
    int max = [result length] - 1;
    int total = 0;

    for (int i = 0; i < max; i++) {
      total += [ALPHABET_STRING rangeOfString:[result substringWithRange:NSMakeRange(i, 1)]].location;
    }

    if ([result characterAtIndex:max] != ALPHABET[total % 43]) {
      @throw [ChecksumException checksumInstance];
    }
    [result deleteCharactersInRange:NSMakeRange(max, 1)];
  }
  if ([result length] == 0) {
    @throw [NotFoundException notFoundInstance];
  }
  NSString * resultString;
  if (extendedMode) {
    resultString = [self decodeExtended:result];
  } else {
    resultString = [NSString stringWithString:result];
  }
  float left = (float)([[start objectAtIndex:1] intValue] + [[start objectAtIndex:0] intValue]) / 2.0f;
  float right = (float)(nextStart + lastStart) / 2.0f;
  
  return [[[Result alloc] init:resultString
                      rawBytes:nil
                  resultPoints:[NSArray arrayWithObjects:[[[ResultPoint alloc] initWithX:left y:(float)rowNumber] autorelease],
                                [[[ResultPoint alloc] initWithX:right y:(float)rowNumber] autorelease], nil]
                        format:kBarcodeFormatCode39] autorelease];
}

- (NSArray *) findAsteriskPattern:(BitArray *)row {
  int width = [row size];
  int rowOffset = 0;

  while (rowOffset < width) {
    if ([row get:rowOffset]) {
      break;
    }
    rowOffset++;
  }

  int counterPosition = 0;
  NSMutableArray * counters = [NSMutableArray arrayWithCapacity:9];
  for (int i = 0; i < 9; i++) {
    [counters addObject:[NSNumber numberWithInt:0]];
  }
  int patternStart = rowOffset;
  BOOL isWhite = NO;
  int patternLength = [counters count];

  for (int i = rowOffset; i < width; i++) {
    BOOL pixel = [row get:i];
    if (pixel ^ isWhite) {
      [counters replaceObjectAtIndex:counterPosition
                          withObject:[NSNumber numberWithInt:[[counters objectAtIndex:counterPosition] intValue] + 1]];
    } else {
      if (counterPosition == patternLength - 1) {
        if ([self toNarrowWidePattern:counters] == ASTERISK_ENCODING) {
          if ([row isRange:MAX(0, patternStart - (i - patternStart) / 2) end:patternStart value:NO]) {
            return [NSArray arrayWithObjects:[NSNumber numberWithInt:patternStart], [NSNumber numberWithInt:i], nil];
          }
        }
        patternStart += [[counters objectAtIndex:0] intValue] + [[counters objectAtIndex:1] intValue];

        for (int y = 2; y < patternLength; y++) {
          [counters replaceObjectAtIndex:y - 2 withObject:[counters objectAtIndex:y]];
        }

        [counters replaceObjectAtIndex:patternLength - 2 withObject:[NSNumber numberWithInt:0]];
        [counters replaceObjectAtIndex:patternLength - 1 withObject:[NSNumber numberWithInt:0]];
        counterPosition--;
      } else {
        counterPosition++;
      }
      [counters replaceObjectAtIndex:counterPosition withObject:[NSNumber numberWithInt:1]];
      isWhite = !isWhite;
    }
  }

  @throw [NotFoundException notFoundInstance];
}

- (int) toNarrowWidePattern:(NSArray *)counters {
  int numCounters = [counters count];
  int maxNarrowCounter = 0;
  int wideCounters;

  do {
    int minCounter = NSIntegerMax;

    for (int i = 0; i < numCounters; i++) {
      int counter = [[counters objectAtIndex:i] intValue];
      if (counter < minCounter && counter > maxNarrowCounter) {
        minCounter = counter;
      }
    }

    maxNarrowCounter = minCounter;
    wideCounters = 0;
    int totalWideCountersWidth = 0;
    int pattern = 0;

    for (int i = 0; i < numCounters; i++) {
      int counter = [[counters objectAtIndex:i] intValue];
      if ([[counters objectAtIndex:i] intValue] > maxNarrowCounter) {
        pattern |= 1 << (numCounters - 1 - i);
        wideCounters++;
        totalWideCountersWidth += counter;
      }
    }

    if (wideCounters == 3) {
      for (int i = 0; i < numCounters && wideCounters > 0; i++) {
        int counter = [[counters objectAtIndex:i] intValue];
        if ([[counters objectAtIndex:i] intValue] > maxNarrowCounter) {
          wideCounters--;
          if ((counter << 1) >= totalWideCountersWidth) {
            return -1;
          }
        }
      }

      return pattern;
    }
  }
   while (wideCounters > 3);
  return -1;
}

- (unichar) patternToChar:(int)pattern {

  for (int i = 0; i < sizeof(CHARACTER_ENCODINGS) / sizeof(int); i++) {
    if (CHARACTER_ENCODINGS[i] == pattern) {
      return ALPHABET[i];
    }
  }

  @throw [NotFoundException notFoundInstance];
}

- (NSString *) decodeExtended:(NSMutableString *)encoded {
  int length = [encoded length];
  NSMutableString * decoded = [NSMutableString stringWithCapacity:length];

  for (int i = 0; i < length; i++) {
    unichar c = [encoded characterAtIndex:i];
    if (c == '+' || c == '$' || c == '%' || c == '/') {
      unichar next = [encoded characterAtIndex:i + 1];
      unichar decodedChar = '\0';

      switch (c) {
      case '+':
        if (next >= 'A' && next <= 'Z') {
          decodedChar = (unichar)(next + 32);
        } else {
          @throw [FormatException formatInstance];
        }
        break;
      case '$':
        if (next >= 'A' && next <= 'Z') {
          decodedChar = (unichar)(next - 64);
        } else {
          @throw [FormatException formatInstance];
        }
        break;
      case '%':
        if (next >= 'A' && next <= 'E') {
          decodedChar = (unichar)(next - 38);
        } else if (next >= 'F' && next <= 'W') {
          decodedChar = (unichar)(next - 11);
        } else {
          @throw [FormatException formatInstance];
        }
        break;
      case '/':
        if (next >= 'A' && next <= 'O') {
          decodedChar = (unichar)(next - 32);
        } else if (next == 'Z') {
          decodedChar = ':';
        } else {
          @throw [FormatException formatInstance];
        }
        break;
      }
      [decoded appendFormat:@"%c", decodedChar];
      i++;
    } else {
      [decoded appendFormat:@"%c", c];
    }
  }

  return decoded;
}

@end
