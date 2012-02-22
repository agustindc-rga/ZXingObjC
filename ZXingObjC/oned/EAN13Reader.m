#import "EAN13Reader.h"
#import "NotFoundException.h"

// For an EAN-13 barcode, the first digit is represented by the parities used
// to encode the next six digits, according to the table below. For example,
// if the barcode is 5 123456 789012 then the value of the first digit is
// signified by using odd for '1', even for '2', even for '3', odd for '4',
// odd for '5', and even for '6'. See http://en.wikipedia.org/wiki/EAN-13
//
//                Parity of next 6 digits
//    Digit   0     1     2     3     4     5
//       0    Odd   Odd   Odd   Odd   Odd   Odd
//       1    Odd   Odd   Even  Odd   Even  Even
//       2    Odd   Odd   Even  Even  Odd   Even
//       3    Odd   Odd   Even  Even  Even  Odd
//       4    Odd   Even  Odd   Odd   Even  Even
//       5    Odd   Even  Even  Odd   Odd   Even
//       6    Odd   Even  Even  Even  Odd   Odd
//       7    Odd   Even  Odd   Even  Odd   Even
//       8    Odd   Even  Odd   Even  Even  Odd
//       9    Odd   Even  Even  Odd   Even  Odd
//
// Note that the encoding for '0' uses the same parity as a UPC barcode. Hence
// a UPC barcode can be converted to an EAN-13 barcode by prepending a 0.
//
// The encoding is represented by the following array, which is a bit pattern
// using Odd = 0 and Even = 1. For example, 5 is represented by:
//
//              Odd Even Even Odd Odd Even
// in binary:
//                0    1    1   0   0    1   == 0x19
//
int FIRST_DIGIT_ENCODINGS[10] = {
  0x00, 0x0B, 0x0D, 0xE, 0x13, 0x19, 0x1C, 0x15, 0x16, 0x1A
};

@interface EAN13Reader ()

- (void) determineFirstDigit:(NSMutableString *)resultString lgPatternFound:(int)lgPatternFound;

@end

@implementation EAN13Reader

- (id) init {
  if (self = [super init]) {
    decodeMiddleCounters = (int*)malloc(sizeof(4) * sizeof(int));
  }
  return self;
}

- (int) decodeMiddle:(BitArray *)row startRange:(NSArray *)startRange resultString:(NSMutableString *)resultString {
  int counters[4];
  counters[0] = 0;
  counters[1] = 0;
  counters[2] = 0;
  counters[3] = 0;
  int end = [row size];
  int rowOffset = [[startRange objectAtIndex:1] intValue];

  int lgPatternFound = 0;

  for (int x = 0; x < 6 && rowOffset < end; x++) {
    int bestMatch = [UPCEANReader decodeDigit:row counters:counters rowOffset:rowOffset patterns:(int**)L_AND_G_PATTERNS];
    [resultString appendFormat:@"%C", (unichar)('0' + bestMatch % 10)];
    for (int i = 0; i < sizeof(counters) / sizeof(int); i++) {
      rowOffset += counters[i];
    }
    if (bestMatch >= 10) {
      lgPatternFound |= 1 << (5 - x);
    }
  }

  [self determineFirstDigit:resultString lgPatternFound:lgPatternFound];

  NSArray * middleRange = [UPCEANReader findGuardPattern:row rowOffset:rowOffset whiteFirst:YES pattern:(int*)MIDDLE_PATTERN];
  rowOffset = [[middleRange objectAtIndex:1] intValue];

  for (int x = 0; x < 6 && rowOffset < end; x++) {
    int bestMatch = [UPCEANReader decodeDigit:row counters:counters rowOffset:rowOffset patterns:(int**)L_PATTERNS];
    [resultString appendFormat:@"%C", (unichar)('0' + bestMatch)];
    for (int i = 0; i < sizeof(counters) / sizeof(int); i++) {
      rowOffset += counters[i];
    }
  }

  return rowOffset;
}

- (BarcodeFormat) barcodeFormat {
  return kBarcodeFormatEan13;
}


/**
 * Based on pattern of odd-even ('L' and 'G') patterns used to encoded the explicitly-encoded
 * digits in a barcode, determines the implicitly encoded first digit and adds it to the
 * result string.
 * 
 * @param resultString string to insert decoded first digit into
 * @param lgPatternFound int whose bits indicates the pattern of odd/even L/G patterns used to
 * encode digits
 * @throws NotFoundException if first digit cannot be determined
 */
- (void) determineFirstDigit:(NSMutableString *)resultString lgPatternFound:(int)lgPatternFound {
  for (int d = 0; d < 10; d++) {
    if (lgPatternFound == FIRST_DIGIT_ENCODINGS[d]) {
      [resultString insertString:[NSString stringWithFormat:@"%C", (unichar)('0' + d)] atIndex:0];
      return;
    }
  }
  @throw [NotFoundException notFoundInstance];
}

- (void) dealloc {
//  free(decodeMiddleCounters);
  [super dealloc];
}

@end
