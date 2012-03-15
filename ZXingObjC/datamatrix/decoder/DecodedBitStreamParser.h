#import "FormatException.h"
#import "BitSource.h"
#import "DecoderResult.h"
#import "UnsupportedEncodingException.h"

/**
 * <p>Data Matrix Codes can encode text as bits in one of several modes, and can use multiple modes
 * in one Data Matrix Code. This class decodes the bits back into text.</p>
 * 
 * <p>See ISO 16022:2006, 5.2.1 - 5.2.9.2</p>
 * 
 * @author bbrown@google.com (Brian Brown)
 * @author Sean Owen
 */

@interface DecodedBitStreamParser : NSObject {
}

+ (DecoderResult *) decode:(NSArray *)bytes;
@end
