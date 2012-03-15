#import "NSMutableArray.h"

/**
 * <p>Implements Reed-Solomon enbcoding, as the name implies.</p>
 * 
 * @author Sean Owen
 * @author William Rucklidge
 */

@interface ReedSolomonEncoder : NSObject {
  GenericGF * field;
  NSMutableArray * cachedGenerators;
}

- (id) initWithField:(GenericGF *)field;
- (void) encode:(NSArray *)toEncode ecBytes:(int)ecBytes;
@end
