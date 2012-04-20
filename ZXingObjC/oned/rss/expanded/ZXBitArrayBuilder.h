/**
 * @author Pablo Orduña, University of Deusto (pablo.orduna@deusto.es)
 * @author Eduardo Castillejo, University of Deusto (eduardo.castillejo@deusto.es)
 */

@class ZXBitArray;

@interface ZXBitArrayBuilder : NSObject

+ (ZXBitArray *) buildBitArray:(NSMutableArray *)pairs;

@end
