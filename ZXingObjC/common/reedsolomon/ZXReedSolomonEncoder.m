#import "ZXGenericGF.h"
#import "ZXGenericGFPoly.h"
#import "ZXReedSolomonEncoder.h"

@interface ZXReedSolomonEncoder ()

@property (nonatomic, retain) NSMutableArray * cachedGenerators;
@property (nonatomic, retain) ZXGenericGF * field;

@end


@implementation ZXReedSolomonEncoder

@synthesize cachedGenerators;
@synthesize field;

- (id)initWithField:(ZXGenericGF *)aField {
  if (self = [super init]) {
    if (![[ZXGenericGF QrCodeField256] isEqual:aField]) {
      @throw [NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Only QR Code is supported at this time"
                                   userInfo:nil];
    }
    self.field = aField;
    int one = 1;
    self.cachedGenerators = [NSMutableArray arrayWithObject:[[[ZXGenericGFPoly alloc] initWithField:aField coefficients:&one coefficientsLen:1] autorelease]];
  }

  return self;
}

- (void)dealloc {
  [cachedGenerators release];
  [field release];

  [super dealloc];
}

- (ZXGenericGFPoly *)buildGenerator:(int)degree {
  if (degree >= self.cachedGenerators.count) {
    ZXGenericGFPoly * lastGenerator = (ZXGenericGFPoly *)[self.cachedGenerators objectAtIndex:[cachedGenerators count] - 1];
    for (int d = [self.cachedGenerators count]; d <= degree; d++) {
      int next[2] = { 1, [field exp:d - 1] };
      ZXGenericGFPoly * nextGenerator = [lastGenerator multiply:[[[ZXGenericGFPoly alloc] initWithField:field coefficients:next coefficientsLen:2] autorelease]];
      [self.cachedGenerators addObject:nextGenerator];
      lastGenerator = nextGenerator;
    }
  }

  return (ZXGenericGFPoly *)[self.cachedGenerators objectAtIndex:degree];
}

- (void)encode:(int*)toEncode toEncodeLen:(int)toEncodeLen ecBytes:(int)ecBytes {
  if (ecBytes == 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"No error correction bytes"
                                 userInfo:nil];
  }
  int dataBytes = toEncodeLen - ecBytes;
  if (dataBytes <= 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"No data bytes provided"
                                 userInfo:nil];
  }
  ZXGenericGFPoly * generator = [self buildGenerator:ecBytes];
  int infoCoefficients[dataBytes];
  for (int i = 0; i < dataBytes; i++) {
    infoCoefficients[i] = toEncode[i];
  }
  ZXGenericGFPoly * info = [[[ZXGenericGFPoly alloc] initWithField:field coefficients:infoCoefficients coefficientsLen:dataBytes] autorelease];
  info = [info multiplyByMonomial:ecBytes coefficient:1];
  ZXGenericGFPoly * remainder = [[info divide:generator] objectAtIndex:1];
  int* coefficients = remainder.coefficients;
  int coefficientsLen = remainder.coefficientsLen;
  int numZeroCoefficients = ecBytes - coefficientsLen;
  for (int i = 0; i < numZeroCoefficients; i++) {
    toEncode[dataBytes + i] = 0;
  }
  for (int i = 0; i < coefficientsLen; i++) {
    toEncode[dataBytes + numZeroCoefficients + i] = coefficients[i];
  }
}

@end
