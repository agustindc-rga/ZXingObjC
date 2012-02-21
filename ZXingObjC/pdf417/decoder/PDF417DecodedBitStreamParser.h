/**
 * <p>This class contains the methods for decoding the PDF417 codewords.</p>
 * 
 * @author SITA Lab (kevin.osullivan@sita.aero)
 */

@class DecoderResult;

@interface PDF417DecodedBitStreamParser : NSObject

+ (DecoderResult *) decode:(NSArray *)codewords;

@end
