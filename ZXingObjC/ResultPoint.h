
/**
 * <p>Encapsulates a point of interest in an image containing a barcode. Typically, this
 * would be the location of a finder pattern or the corner of the barcode, for example.</p>
 * 
 * @author Sean Owen
 */

@interface ResultPoint : NSObject {
  float x;
  float y;
}

@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
- (id) init:(float)x y:(float)y;
- (BOOL) isEqualTo:(NSObject *)other;
- (int) hash;
- (NSString *) description;
+ (void) orderBestPatterns:(NSArray *)patterns;
+ (float) distance:(ResultPoint *)pattern1 pattern2:(ResultPoint *)pattern2;
@end
