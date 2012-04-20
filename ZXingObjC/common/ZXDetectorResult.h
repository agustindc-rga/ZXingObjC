/**
 * <p>Encapsulates the result of detecting a barcode in an image. This includes the raw
 * matrix of black/white pixels corresponding to the barcode, and possibly points of interest
 * in the image, like the location of finder patterns or corners of the barcode in the image.</p>
 * 
 * @author Sean Owen
 */

@class ZXBitMatrix;

@interface ZXDetectorResult : NSObject {
  ZXBitMatrix * bits;
  NSArray * points;
}

@property(nonatomic, retain, readonly) ZXBitMatrix * bits;
@property(nonatomic, retain, readonly) NSArray * points;

- (id) initWithBits:(ZXBitMatrix *)bits points:(NSArray *)points;

@end
