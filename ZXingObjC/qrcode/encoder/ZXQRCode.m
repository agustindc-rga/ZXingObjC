#import "ZXByteMatrix.h"
#import "ZXErrorCorrectionLevel.h"
#import "ZXMode.h"
#import "ZXQRCode.h"

int const NUM_MASK_PATTERNS = 8;

@implementation ZXQRCode

@synthesize mode;
@synthesize ecLevel;
@synthesize version;
@synthesize matrixWidth;
@synthesize maskPattern;
@synthesize numTotalBytes;
@synthesize numDataBytes;
@synthesize numECBytes;
@synthesize numRSBlocks;
@synthesize matrix;

- (id)init {
  if (self = [super init]) {
    self.mode = nil;
    self.ecLevel = nil;
    self.version = -1;
    self.matrixWidth = -1;
    self.maskPattern = -1;
    self.numTotalBytes = -1;
    self.numDataBytes = -1;
    self.numECBytes = -1;
    self.numRSBlocks = -1;
    self.matrix = nil;
  }

  return self;
}

- (void)dealloc {
  [mode release];
  [ecLevel release];
  [matrix release];

  [super dealloc];
}

- (int)at:(int)x y:(int)y {
  int value = [self.matrix get:x y:y];
  if (!(value == 0 || value == 1)) {
    [NSException raise:NSInternalInconsistencyException format:@"Bad value"];
  }
  return value;
}

- (BOOL)isValid {
  return self.mode != nil && self.ecLevel != nil && self.version != -1 && self.matrixWidth != -1 && self.maskPattern != -1 && self.numTotalBytes != -1 && self.numDataBytes != -1 && self.numECBytes != -1 && self.numRSBlocks != -1 && [ZXQRCode isValidMaskPattern:self.maskPattern] && self.numTotalBytes == self.numDataBytes + self.numECBytes && self.matrix != nil && self.matrixWidth == self.matrix.width && self.matrix.width == self.matrix.height;
}

- (NSString *)description {
  NSMutableString *result = [NSMutableString stringWithCapacity:200];
  [result appendFormat:@"<<\n mode: %@", self.mode];
  [result appendFormat:@"\n ecLevel: %@", self.ecLevel];
  [result appendFormat:@"\n version: %d", self.version];
  [result appendFormat:@"\n matrixWidth: %d", self.matrixWidth];
  [result appendFormat:@"\n maskPattern: %d", self.maskPattern];
  [result appendFormat:@"\n numTotalBytes: %d", self.numTotalBytes];
  [result appendFormat:@"\n numDataBytes: %d", self.numDataBytes];
  [result appendFormat:@"\n numECBytes: %d", self.numECBytes];
  [result appendFormat:@"\n numRSBlocks: %d", self.numRSBlocks];
  if (self.matrix == nil) {
    [result appendString:@"\n matrix: null\n"];
  } else {
    [result appendFormat:@"\n matrix:\n%@", [self.matrix description]];
  }
  [result appendString:@">>\n"];
  return result;
}

+ (BOOL)isValidMaskPattern:(int)maskPattern {
  return maskPattern >= 0 && maskPattern < NUM_MASK_PATTERNS;
}

@end
