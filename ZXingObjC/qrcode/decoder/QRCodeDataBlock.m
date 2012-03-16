#import "ErrorCorrectionLevel.h"
#import "QRCodeDataBlock.h"
#import "QRCodeVersion.h"

@implementation QRCodeDataBlock

@synthesize codewords, numDataCodewords;

- (id) init:(int)theNumDataCodewords codewords:(NSMutableArray *)theCodewords {
  if (self = [super init]) {
    numDataCodewords = theNumDataCodewords;
    codewords = [theCodewords retain];
  }
  return self;
}


/**
 * <p>When QR Codes use multiple data blocks, they are actually interleaved.
 * That is, the first byte of data block 1 to n is written, then the second bytes, and so on. This
 * method will separate the data into original blocks.</p>
 * 
 * @param rawCodewords bytes as read directly from the QR Code
 * @param version version of the QR Code
 * @param ecLevel error-correction level of the QR Code
 * @return DataBlocks containing original bytes, "de-interleaved" from representation in the
 * QR Code
 */
+ (NSArray *) getDataBlocks:(NSArray *)rawCodewords version:(QRCodeVersion *)version ecLevel:(ErrorCorrectionLevel *)ecLevel {
  if ([rawCodewords count] != [version totalCodewords]) {
    [NSException raise:NSInvalidArgumentException format:@"Invalid codewords count"];
  }

  QRCodeECBlocks * ecBlocks = [version getECBlocksForLevel:ecLevel];

  int totalBlocks = 0;
  NSArray * ecBlockArray = [ecBlocks ecBlocks];
  for (int i = 0; i < [ecBlockArray count]; i++) {
    totalBlocks += [[ecBlockArray objectAtIndex:i] count];
  }

  NSMutableArray * result = [NSMutableArray arrayWithCapacity:totalBlocks];
  for (QRCodeECB *ecBlock in ecBlockArray) {
    for (int i = 0; i < [ecBlock count]; i++) {
      int numDataCodewords = [ecBlock dataCodewords];
      int numBlockCodewords = [ecBlocks eCCodewordsPerBlock] + numDataCodewords;
      NSMutableArray *newCodewords = [NSMutableArray arrayWithCapacity:numBlockCodewords];
      for (int j = 0; j < numBlockCodewords; j++) {
        [newCodewords addObject:[NSNull null]];
      }

      [result addObject:[[[QRCodeDataBlock alloc] init:numDataCodewords codewords:newCodewords] autorelease]];
    }
  }

  int shorterBlocksTotalCodewords = [[[result objectAtIndex:0] codewords] count];
  int longerBlocksStartAt = [result count] - 1;

  while (longerBlocksStartAt >= 0) {
    int numCodewords = [[[result objectAtIndex:longerBlocksStartAt] codewords] count];
    if (numCodewords == shorterBlocksTotalCodewords) {
      break;
    }
    longerBlocksStartAt--;
  }

  longerBlocksStartAt++;
  int shorterBlocksNumDataCodewords = shorterBlocksTotalCodewords - [ecBlocks eCCodewordsPerBlock];
  int rawCodewordsOffset = 0;
  int numResultBlocks = [result count];

  for (int i = 0; i < shorterBlocksNumDataCodewords; i++) {
    for (int j = 0; j < numResultBlocks; j++) {
      [[[result objectAtIndex:j] codewords] replaceObjectAtIndex:i withObject:[rawCodewords objectAtIndex:rawCodewordsOffset++]];
    }
  }

  for (int j = longerBlocksStartAt; j < numResultBlocks; j++) {
    [[[result objectAtIndex:j] codewords] replaceObjectAtIndex:shorterBlocksNumDataCodewords withObject:[rawCodewords objectAtIndex:rawCodewordsOffset++]];
  }

  int max = [[[result objectAtIndex:0] codewords] count];
  for (int i = shorterBlocksNumDataCodewords; i < max; i++) {
    for (int j = 0; j < numResultBlocks; j++) {
      int iOffset = j < longerBlocksStartAt ? i : i + 1;
      [[[result objectAtIndex:j] codewords] replaceObjectAtIndex:iOffset withObject:[rawCodewords objectAtIndex:rawCodewordsOffset++]];
    }
  }

  return result;
}

- (void) dealloc {
  [codewords release];
  [super dealloc];
}

@end
