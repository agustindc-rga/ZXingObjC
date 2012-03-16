#import "AI01weightDecoder.h"
#import "GeneralAppIdDecoder.h"

@implementation AI01weightDecoder

- (void) encodeCompressedWeight:(NSMutableString *)buf currentPos:(int)currentPos weightSize:(int)weightSize {
  int originalWeightNumeric = [generalDecoder extractNumericValueFromBitArray:currentPos bits:weightSize];
  [self addWeightCode:buf weight:originalWeightNumeric];

  int weightNumeric = [self checkWeight:originalWeightNumeric];

  int currentDivisor = 100000;
  for (int i = 0; i < 5; ++i) {
    if (weightNumeric / currentDivisor == 0) {
      [buf appendString:@"0"];
    }
    currentDivisor /= 10;
  }

  [buf appendFormat:@"%d", weightNumeric];
}

- (void) addWeightCode:(NSMutableString *)buf weight:(int)weight {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

- (int) checkWeight:(int)weight {
  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

@end
