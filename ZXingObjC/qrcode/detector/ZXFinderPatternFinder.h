/**
 * <p>This class attempts to find finder patterns in a QR Code. Finder patterns are the square
 * markers at three corners of a QR Code.</p>
 * 
 * <p>This class is thread-safe but not reentrant. Each thread must allocate its own object.
 * 
 * @author Sean Owen
 */

extern int const FINDER_PATTERN_MIN_SKIP;
extern int const FINDER_PATTERN_MAX_MODULES;

@class ZXBitMatrix, ZXFinderPatternInfo;
@protocol ZXResultPointCallback;

@interface ZXFinderPatternFinder : NSObject {
  ZXBitMatrix * image;
  NSMutableArray * possibleCenters;
  BOOL hasSkipped;
  int crossCheckStateCount[5];
  id <ZXResultPointCallback> resultPointCallback;
}

@property (nonatomic, readonly) ZXBitMatrix * image;
@property (nonatomic, readonly, retain) NSMutableArray * possibleCenters;

- (id) initWithImage:(ZXBitMatrix *)image;
- (id) initWithImage:(ZXBitMatrix *)image resultPointCallback:(id <ZXResultPointCallback>)resultPointCallback;
- (ZXFinderPatternInfo *) find:(NSMutableDictionary *)hints;
+ (BOOL) foundPatternCross:(int[])stateCount;
- (BOOL) handlePossibleCenter:(int[])stateCount i:(int)i j:(int)j;

@end
