/**
 * @author bbrown@google.com (Brian Brown)
 */

@class BitMatrix, QRCodeVersion;

@interface BitMatrixParser : NSObject {
  BitMatrix * mappingBitMatrix;
  BitMatrix * readMappingMatrix;
  QRCodeVersion * version;
}

@property (nonatomic, readonly) QRCodeVersion* version;

- (id) initWithBitMatrix:(BitMatrix *)bitMatrix;
- (NSArray *) readCodewords;
- (BOOL) readModule:(int)row column:(int)column numRows:(int)numRows numColumns:(int)numColumns;
- (int) readUtah:(int)row column:(int)column numRows:(int)numRows numColumns:(int)numColumns;
- (int) readCorner1:(int)numRows numColumns:(int)numColumns;
- (int) readCorner2:(int)numRows numColumns:(int)numColumns;
- (int) readCorner3:(int)numRows numColumns:(int)numColumns;
- (int) readCorner4:(int)numRows numColumns:(int)numColumns;
- (BitMatrix *) extractDataRegion:(BitMatrix *)bitMatrix;

@end
