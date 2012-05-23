#import "ZXAlignmentPattern.h"
#import "ZXAlignmentPatternFinder.h"
#import "ZXBitMatrix.h"
#import "ZXDecodeHints.h"
#import "ZXDetectorResult.h"
#import "ZXFinderPatternFinder.h"
#import "ZXFinderPatternInfo.h"
#import "ZXGridSampler.h"
#import "ZXNotFoundException.h"
#import "ZXPerspectiveTransform.h"
#import "ZXQRCodeDetector.h"
#import "ZXQRCodeFinderPattern.h"
#import "ZXQRCodeVersion.h"
#import "ZXResultPoint.h"
#import "ZXResultPointCallback.h"

@interface ZXQRCodeDetector ()

- (float) calculateModuleSizeOneWay:(ZXResultPoint *)pattern otherPattern:(ZXResultPoint *)otherPattern;
+ (int) round:(float)d;
- (ZXBitMatrix *) sampleGrid:(ZXBitMatrix *)image transform:(ZXPerspectiveTransform *)transform dimension:(int)dimension;
- (float) sizeOfBlackWhiteBlackRun:(int)fromX fromY:(int)fromY toX:(int)toX toY:(int)toY;
- (float) sizeOfBlackWhiteBlackRunBothWays:(int)fromX fromY:(int)fromY toX:(int)toX toY:(int)toY;

@end

@implementation ZXQRCodeDetector

@synthesize image, resultPointCallback;

- (id) initWithImage:(ZXBitMatrix *)anImage {
  if (self = [super init]) {
    image = [anImage retain];
  }
  return self;
}


/**
 * <p>Detects a QR Code in an image, simply.</p>
 * 
 * @return {@link ZXDetectorResult} encapsulating results of detecting a QR Code
 * @throws NotFoundException if no QR Code can be found
 */
- (ZXDetectorResult *) detect {
  return [self detect:nil];
}


/**
 * <p>Detects a QR Code in an image, simply.</p>
 * 
 * @param hints optional hints to detector
 * @return {@link NotFoundException} encapsulating results of detecting a QR Code
 * @throws NotFoundException if QR Code cannot be found
 * @throws FormatException if a QR Code cannot be decoded
 */
- (ZXDetectorResult *) detect:(ZXDecodeHints *)hints {
  resultPointCallback = hints == nil ? nil : hints.resultPointCallback;

  ZXFinderPatternFinder * finder = [[[ZXFinderPatternFinder alloc] initWithImage:image resultPointCallback:resultPointCallback] autorelease];
  ZXFinderPatternInfo * info = [finder find:hints];

  return [self processFinderPatternInfo:info];
}

- (ZXDetectorResult *) processFinderPatternInfo:(ZXFinderPatternInfo *)info {
  ZXQRCodeFinderPattern * topLeft = [info topLeft];
  ZXQRCodeFinderPattern * topRight = [info topRight];
  ZXQRCodeFinderPattern * bottomLeft = [info bottomLeft];

  float moduleSize = [self calculateModuleSize:topLeft topRight:topRight bottomLeft:bottomLeft];
  if (moduleSize < 1.0f) {
    @throw [ZXNotFoundException notFoundInstance];
  }
  int dimension = [ZXQRCodeDetector computeDimension:topLeft topRight:topRight bottomLeft:bottomLeft moduleSize:moduleSize];
  ZXQRCodeVersion * provisionalVersion = [ZXQRCodeVersion getProvisionalVersionForDimension:dimension];
  int modulesBetweenFPCenters = [provisionalVersion dimensionForVersion] - 7;

  ZXAlignmentPattern * alignmentPattern = nil;
  if ([[provisionalVersion alignmentPatternCenters] count] > 0) {
    float bottomRightX = [topRight x] - [topLeft x] + [bottomLeft x];
    float bottomRightY = [topRight y] - [topLeft y] + [bottomLeft y];

    float correctionToTopLeft = 1.0f - 3.0f / (float)modulesBetweenFPCenters;
    int estAlignmentX = (int)([topLeft x] + correctionToTopLeft * (bottomRightX - [topLeft x]));
    int estAlignmentY = (int)([topLeft y] + correctionToTopLeft * (bottomRightY - [topLeft y]));

    for (int i = 4; i <= 16; i <<= 1) {
      @try {
        alignmentPattern = [self findAlignmentInRegion:moduleSize estAlignmentX:estAlignmentX estAlignmentY:estAlignmentY allowanceFactor:(float)i];
        break;
      }
      @catch (ZXNotFoundException * re) {
      }
    }
  }

  ZXPerspectiveTransform * transform = [ZXQRCodeDetector createTransform:topLeft topRight:topRight bottomLeft:bottomLeft alignmentPattern:alignmentPattern dimension:dimension];
  ZXBitMatrix * bits = [self sampleGrid:image transform:transform dimension:dimension];
  NSArray * points;
  if (alignmentPattern == nil) {
    points = [NSArray arrayWithObjects:bottomLeft, topLeft, topRight, nil];
  } else {
    points = [NSArray arrayWithObjects:bottomLeft, topLeft, topRight, alignmentPattern, nil];
  }
  return [[[ZXDetectorResult alloc] initWithBits:bits points:points] autorelease];
}

+ (ZXPerspectiveTransform *) createTransform:(ZXResultPoint *)topLeft topRight:(ZXResultPoint *)topRight bottomLeft:(ZXResultPoint *)bottomLeft alignmentPattern:(ZXResultPoint *)alignmentPattern dimension:(int)dimension {
  float dimMinusThree = (float)dimension - 3.5f;
  float bottomRightX;
  float bottomRightY;
  float sourceBottomRightX;
  float sourceBottomRightY;
  if (alignmentPattern != nil) {
    bottomRightX = [alignmentPattern x];
    bottomRightY = [alignmentPattern y];
    sourceBottomRightX = sourceBottomRightY = dimMinusThree - 3.0f;
  } else {
    bottomRightX = ([topRight x] - [topLeft x]) + [bottomLeft x];
    bottomRightY = ([topRight y] - [topLeft y]) + [bottomLeft y];
    sourceBottomRightX = sourceBottomRightY = dimMinusThree;
  }
  return [ZXPerspectiveTransform quadrilateralToQuadrilateral:3.5f
                                                         y0:3.5f
                                                         x1:dimMinusThree
                                                         y1:3.5f
                                                         x2:sourceBottomRightX
                                                         y2:sourceBottomRightY
                                                         x3:3.5f
                                                         y3:dimMinusThree
                                                        x0p:[topLeft x]
                                                        y0p:[topLeft y]
                                                        x1p:[topRight x]
                                                        y1p:[topRight y]
                                                        x2p:bottomRightX
                                                        y2p:bottomRightY
                                                        x3p:[bottomLeft x]
                                                        y3p:[bottomLeft y]];
}

- (ZXBitMatrix *) sampleGrid:(ZXBitMatrix *)anImage transform:(ZXPerspectiveTransform *)transform dimension:(int)dimension {
  ZXGridSampler * sampler = [ZXGridSampler instance];
  return [sampler sampleGrid:anImage dimensionX:dimension dimensionY:dimension transform:transform];
}


/**
 * <p>Computes the dimension (number of modules on a size) of the QR Code based on the position
 * of the finder patterns and estimated module size.</p>
 */
+ (int) computeDimension:(ZXResultPoint *)topLeft topRight:(ZXResultPoint *)topRight bottomLeft:(ZXResultPoint *)bottomLeft moduleSize:(float)moduleSize {
  int tltrCentersDimension = [ZXQRCodeDetector round:[ZXResultPoint distance:topLeft pattern2:topRight] / moduleSize];
  int tlblCentersDimension = [ZXQRCodeDetector round:[ZXResultPoint distance:topLeft pattern2:bottomLeft] / moduleSize];
  int dimension = ((tltrCentersDimension + tlblCentersDimension) >> 1) + 7;

  switch (dimension & 0x03) {
  case 0:
    dimension++;
    break;
  case 2:
    dimension--;
    break;
  case 3:
    @throw [ZXNotFoundException notFoundInstance];
  }
  return dimension;
}


/**
 * <p>Computes an average estimated module size based on estimated derived from the positions
 * of the three finder patterns.</p>
 */
- (float) calculateModuleSize:(ZXResultPoint *)topLeft topRight:(ZXResultPoint *)topRight bottomLeft:(ZXResultPoint *)bottomLeft {
  return ([self calculateModuleSizeOneWay:topLeft otherPattern:topRight] + [self calculateModuleSizeOneWay:topLeft otherPattern:bottomLeft]) / 2.0f;
}


/**
 * <p>Estimates module size based on two finder patterns -- it uses
 * {@link #sizeOfBlackWhiteBlackRunBothWays(int, int, int, int)} to figure the
 * width of each, measuring along the axis between their centers.</p>
 */
- (float) calculateModuleSizeOneWay:(ZXResultPoint *)pattern otherPattern:(ZXResultPoint *)otherPattern {
  float moduleSizeEst1 = [self sizeOfBlackWhiteBlackRunBothWays:(int)[pattern x] fromY:(int)[pattern y] toX:(int)[otherPattern x] toY:(int)[otherPattern y]];
  float moduleSizeEst2 = [self sizeOfBlackWhiteBlackRunBothWays:(int)[otherPattern x] fromY:(int)[otherPattern y] toX:(int)[pattern x] toY:(int)[pattern y]];
  if (isnan(moduleSizeEst1)) {
    return moduleSizeEst2 / 7.0f;
  }
  if (isnan(moduleSizeEst2)) {
    return moduleSizeEst1 / 7.0f;
  }
  return (moduleSizeEst1 + moduleSizeEst2) / 14.0f;
}


/**
 * See {@link #sizeOfBlackWhiteBlackRun(int, int, int, int)}; computes the total width of
 * a finder pattern by looking for a black-white-black run from the center in the direction
 * of another point (another finder pattern center), and in the opposite direction too.</p>
 */
- (float) sizeOfBlackWhiteBlackRunBothWays:(int)fromX fromY:(int)fromY toX:(int)toX toY:(int)toY {
  float result = [self sizeOfBlackWhiteBlackRun:fromX fromY:fromY toX:toX toY:toY];
  float scale = 1.0f;
  int otherToX = fromX - (toX - fromX);
  if (otherToX < 0) {
    scale = (float)fromX / (float)(fromX - otherToX);
    otherToX = 0;
  } else if (otherToX > [image width]) {
    scale = (float)([image width] - fromX) / (float)(otherToX - fromX);
    otherToX = [image width];
  }
  int otherToY = (int)(fromY - (toY - fromY) * scale);

  scale = 1.0f;
  if (otherToY < 0) {
    scale = (float)fromY / (float)(fromY - otherToY);
    otherToY = 0;
  }
   else if (otherToY > [image height]) {
    scale = (float)([image height] - fromY) / (float)(otherToY - fromY);
    otherToY = [image height];
  }
  otherToX = (int)(fromX + (otherToX - fromX) * scale);

  result += [self sizeOfBlackWhiteBlackRun:fromX fromY:fromY toX:otherToX toY:otherToY];
  return result;
}


/**
 * <p>This method traces a line from a point in the image, in the direction towards another point.
 * It begins in a black region, and keeps going until it finds white, then black, then white again.
 * It reports the distance from the start to this point.</p>
 * 
 * <p>This is used when figuring out how wide a finder pattern is, when the finder pattern
 * may be skewed or rotated.</p>
 */
- (float) sizeOfBlackWhiteBlackRun:(int)fromX fromY:(int)fromY toX:(int)toX toY:(int)toY {
  BOOL steep = abs(toY - fromY) > abs(toX - fromX);
  if (steep) {
    int temp = fromX;
    fromX = fromY;
    fromY = temp;
    temp = toX;
    toX = toY;
    toY = temp;
  }

  int dx = abs(toX - fromX);
  int dy = abs(toY - fromY);
  int error = -dx >> 1;
  int xstep = fromX < toX ? 1 : -1;
  int ystep = fromY < toY ? 1 : -1;

  int state = 0;
  for (int x = fromX, y = fromY; x != toX; x += xstep) {
    int realX = steep ? y : x;
    int realY = steep ? x : y;

    if (state == 1) {
      if ([image get:realX y:realY]) {
        state++;
      }
    } else {
      if (![image get:realX y:realY]) {
        state++;
      }
    }

    if (state == 3) {
      int diffX = x - fromX;
      int diffY = y - fromY;
      if (xstep < 0) {
        diffX++;
      }
      return (float)sqrt((double)(diffX * diffX + diffY * diffY));
    }
    error += dy;
    if (error > 0) {
      if (y == toY) {
        break;
      }
      y += ystep;
      error -= dx;
    }
  }

  int diffX = toX - fromX;
  int diffY = toY - fromY;
  return (float)sqrt((double)(diffX * diffX + diffY * diffY));
}


/**
 * <p>Attempts to locate an alignment pattern in a limited region of the image, which is
 * guessed to contain it. This method uses {@link ZXAlignmentPattern}.</p>
 * 
 * @param overallEstModuleSize estimated module size so far
 * @param estAlignmentX x coordinate of center of area probably containing alignment pattern
 * @param estAlignmentY y coordinate of above
 * @param allowanceFactor number of pixels in all directions to search from the center
 * @return {@link ZXAlignmentPattern} if found, or null otherwise
 * @throws NotFoundException if an unexpected error occurs during detection
 */
- (ZXAlignmentPattern *) findAlignmentInRegion:(float)overallEstModuleSize estAlignmentX:(int)estAlignmentX estAlignmentY:(int)estAlignmentY allowanceFactor:(float)allowanceFactor {
  int allowance = (int)(allowanceFactor * overallEstModuleSize);
  int alignmentAreaLeftX = MAX(0, estAlignmentX - allowance);
  int alignmentAreaRightX = MIN([image width] - 1, estAlignmentX + allowance);
  if (alignmentAreaRightX - alignmentAreaLeftX < overallEstModuleSize * 3) {
    @throw [ZXNotFoundException notFoundInstance];
  }

  int alignmentAreaTopY = MAX(0, estAlignmentY - allowance);
  int alignmentAreaBottomY = MIN([image height] - 1, estAlignmentY + allowance);
  if (alignmentAreaBottomY - alignmentAreaTopY < overallEstModuleSize * 3) {
    @throw [ZXNotFoundException notFoundInstance];
  }

  ZXAlignmentPatternFinder * alignmentFinder = [[[ZXAlignmentPatternFinder alloc] initWithImage:image
                                                                                     startX:alignmentAreaLeftX
                                                                                     startY:alignmentAreaTopY
                                                                                      width:alignmentAreaRightX - alignmentAreaLeftX
                                                                                     height:alignmentAreaBottomY - alignmentAreaTopY
                                                                                     moduleSize:overallEstModuleSize
                                                                                     resultPointCallback:resultPointCallback] autorelease];
  return [alignmentFinder find];
}


/**
 * Ends up being a bit faster than Math.round(). This merely rounds its argument to the nearest int,
 * where x.5 rounds up.
 */
+ (int) round:(float)d {
  return (int)(d + 0.5f);
}

- (void) dealloc {
  [image release];
  [resultPointCallback release];
  [super dealloc];
}

@end
