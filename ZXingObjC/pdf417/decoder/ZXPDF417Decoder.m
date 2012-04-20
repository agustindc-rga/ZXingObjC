#import "ZXBitMatrix.h"
#import "ZXFormatException.h"
#import "ZXPDF417BitMatrixParser.h"
#import "ZXPDF417DecodedBitStreamParser.h"
#import "ZXPDF417Decoder.h"

int const MAX_ERRORS = 3;
int const MAX_EC_CODEWORDS = 512;

@interface ZXPDF417Decoder ()

- (int) correctErrors:(NSArray *)codewords erasures:(NSArray *)erasures numECCodewords:(int)numECCodewords;
- (void) verifyCodewordCount:(NSMutableArray *)codewords numECCodewords:(int)numECCodewords;

@end

@implementation ZXPDF417Decoder

/**
 * <p>Convenience method that can decode a PDF417 Code represented as a 2D array of booleans.
 * "true" is taken to mean a black module.</p>
 * 
 * @param image booleans representing white/black PDF417 modules
 * @return text and bytes encoded within the PDF417 Code
 * @throws NotFoundException if the PDF417 Code cannot be decoded
 */
- (ZXDecoderResult *) decode:(BOOL **)image {
  int dimension = sizeof(image) / sizeof(BOOL *);
  ZXBitMatrix * bits = [[[ZXBitMatrix alloc] initWithDimension:dimension] autorelease];
  for (int i = 0; i < dimension; i++) {
    for (int j = 0; j < dimension; j++) {
      if (image[j][i]) {
        [bits set:j y:i];
      }
    }
  }
  return [self decodeMatrix:bits];
}


/**
 * <p>Decodes a PDF417 Code represented as a {@link BitMatrix}.
 * A 1 or "true" is taken to mean a black module.</p>
 * 
 * @param bits booleans representing white/black PDF417 Code modules
 * @return text and bytes encoded within the PDF417 Code
 * @throws FormatException if the PDF417 Code cannot be decoded
 */
- (ZXDecoderResult *) decodeMatrix:(ZXBitMatrix *)bits {
  ZXPDF417BitMatrixParser * parser = [[[ZXPDF417BitMatrixParser alloc] initWithBitMatrix:bits] autorelease];
  NSMutableArray * codewords = [[[parser readCodewords] mutableCopy] autorelease];
  if (codewords == nil || [codewords count] == 0) {
    @throw [ZXFormatException formatInstance];
  }

  int ecLevel = [parser ecLevel];
  int numECCodewords = 1 << (ecLevel + 1);
  NSArray * erasures = [parser erasures];

  [self correctErrors:codewords erasures:erasures numECCodewords:numECCodewords];
  [self verifyCodewordCount:codewords numECCodewords:numECCodewords];

  return [ZXPDF417DecodedBitStreamParser decode:codewords];
}


/**
 * Verify that all is OK with the codeword array.
 * 
 * @param codewords
 * @return an index to the first data codeword.
 * @throws FormatException
 */
- (void) verifyCodewordCount:(NSMutableArray *)codewords numECCodewords:(int)numECCodewords {
  if ([codewords count] < 4) {
    @throw [ZXFormatException formatInstance];
  }

  int numberOfCodewords = [[codewords objectAtIndex:0] intValue];
  if (numberOfCodewords > [codewords count]) {
    @throw [ZXFormatException formatInstance];
  }
  if (numberOfCodewords == 0) {
    if (numECCodewords < [codewords count]) {
      [codewords replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:[codewords count] - numECCodewords]];
    } else {
      @throw [ZXFormatException formatInstance];
    }
  }
}


/**
 * <p>Given data and error-correction codewords received, possibly corrupted by errors, attempts to
 * correct the errors in-place using Reed-Solomon error correction.</p>
 * 
 * @param codewords   data and error correction codewords
 * @throws ChecksumException if error correction fails
 */
- (int) correctErrors:(NSArray *)codewords erasures:(NSArray *)erasures numECCodewords:(int)numECCodewords {
  if ((erasures != nil && [erasures count] > numECCodewords / 2 + MAX_ERRORS) || numECCodewords < 0 || numECCodewords > MAX_EC_CODEWORDS) {
    @throw [ZXFormatException formatInstance];
  }

  int result = 0;
  if (erasures != nil) {
    int numErasures = [erasures count];
    if (result > 0) {
      numErasures -= result;
    }
    if (numErasures > MAX_ERRORS) {
      @throw [ZXFormatException formatInstance];
    }
  }
  return result;
}

@end
