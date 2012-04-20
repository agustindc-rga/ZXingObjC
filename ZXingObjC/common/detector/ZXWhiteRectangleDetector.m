#import "ZXNotFoundException.h"
#import "ZXWhiteRectangleDetector.h"

@interface ZXWhiteRectangleDetector () {
  int height;
  int width;
  int leftInit;
  int rightInit;
  int downInit;
  int upInit;
}

@property (nonatomic, retain) ZXBitMatrix *image;

- (NSArray *) centerEdges:(ZXResultPoint *)y z:(ZXResultPoint *)z x:(ZXResultPoint *)x t:(ZXResultPoint *)t;
- (BOOL) containsBlackPoint:(int)a b:(int)b fixed:(int)fixed horizontal:(BOOL)horizontal;
- (ZXResultPoint *) getBlackPointOnSegment:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY;
- (int) distanceL2:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY;

@end

int const INIT_SIZE = 30;
int const CORR = 1;

@implementation ZXWhiteRectangleDetector

@synthesize image;

/**
 * @throws NotFoundException if image is too small
 */
- (id) initWithImage:(ZXBitMatrix *)anImage {
  if (self = [super init]) {
    self.image = anImage;
    height = [anImage height];
    width = [anImage width];
    leftInit = (width - INIT_SIZE) >> 1;
    rightInit = (width + INIT_SIZE) >> 1;
    upInit = (height - INIT_SIZE) >> 1;
    downInit = (height + INIT_SIZE) >> 1;
    if (upInit < 0 || leftInit < 0 || downInit >= height || rightInit >= width) {
      @throw [ZXNotFoundException notFoundInstance];
    }
  }
  return self;
}


/**
 * @throws NotFoundException if image is too small
 */
- (id) initWithImage:(ZXBitMatrix *)anImage initSize:(int)initSize x:(int)x y:(int)y {
  if (self = [super init]) {
    self.image = anImage;
    height = [anImage height];
    width = [anImage width];
    int halfsize = initSize >> 1;
    leftInit = x - halfsize;
    rightInit = x + halfsize;
    upInit = y - halfsize;
    downInit = y + halfsize;
    if (upInit < 0 || leftInit < 0 || downInit >= height || rightInit >= width) {
      @throw [ZXNotFoundException notFoundInstance];
    }
  }
  return self;
}


/**
 * <p>
 * Detects a candidate barcode-like rectangular region within an image. It
 * starts around the center of the image, increases the size of the candidate
 * region until it finds a white rectangular region.
 * </p>
 * 
 * @return {@link ResultPoint[]} describing the corners of the rectangular
 * region. The first and last points are opposed on the diagonal, as
 * are the second and third. The first point will be the topmost
 * point and the last, the bottommost. The second point will be
 * leftmost and the third, the rightmost
 * @throws NotFoundException if no Data Matrix Code can be found
 */
- (NSArray *) detect {
  int left = leftInit;
  int right = rightInit;
  int up = upInit;
  int down = downInit;
  BOOL sizeExceeded = NO;
  BOOL aBlackPointFoundOnBorder = YES;
  BOOL atLeastOneBlackPointFoundOnBorder = NO;

  while (aBlackPointFoundOnBorder) {
    aBlackPointFoundOnBorder = NO;
    BOOL rightBorderNotWhite = YES;

    while (rightBorderNotWhite && right < width) {
      rightBorderNotWhite = [self containsBlackPoint:up b:down fixed:right horizontal:NO];
      if (rightBorderNotWhite) {
        right++;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (right >= width) {
      sizeExceeded = YES;
      break;
    }
    BOOL bottomBorderNotWhite = YES;

    while (bottomBorderNotWhite && down < height) {
      bottomBorderNotWhite = [self containsBlackPoint:left b:right fixed:down horizontal:YES];
      if (bottomBorderNotWhite) {
        down++;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (down >= height) {
      sizeExceeded = YES;
      break;
    }
    BOOL leftBorderNotWhite = YES;

    while (leftBorderNotWhite && left >= 0) {
      leftBorderNotWhite = [self containsBlackPoint:up b:down fixed:left horizontal:NO];
      if (leftBorderNotWhite) {
        left--;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (left < 0) {
      sizeExceeded = YES;
      break;
    }
    BOOL topBorderNotWhite = YES;

    while (topBorderNotWhite && up >= 0) {
      topBorderNotWhite = [self containsBlackPoint:left b:right fixed:up horizontal:YES];
      if (topBorderNotWhite) {
        up--;
        aBlackPointFoundOnBorder = YES;
      }
    }

    if (up < 0) {
      sizeExceeded = YES;
      break;
    }
    if (aBlackPointFoundOnBorder) {
      atLeastOneBlackPointFoundOnBorder = YES;
    }
  }

  if (!sizeExceeded && atLeastOneBlackPointFoundOnBorder) {
    int maxSize = right - left;
    ZXResultPoint * z = nil;

    for (int i = 1; i < maxSize; i++) {
      z = [self getBlackPointOnSegment:left aY:down - i bX:left + i bY:down];
      if (z != nil) {
        break;
      }
    }

    if (z == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }
    ZXResultPoint * t = nil;

    for (int i = 1; i < maxSize; i++) {
      t = [self getBlackPointOnSegment:left aY:up + i bX:left + i bY:up];
      if (t != nil) {
        break;
      }
    }

    if (t == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }
    ZXResultPoint * x = nil;

    for (int i = 1; i < maxSize; i++) {
      x = [self getBlackPointOnSegment:right aY:up + i bX:right - i bY:up];
      if (x != nil) {
        break;
      }
    }

    if (x == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }
    ZXResultPoint * y = nil;

    for (int i = 1; i < maxSize; i++) {
      y = [self getBlackPointOnSegment:right aY:down - i bX:right - i bY:down];
      if (y != nil) {
        break;
      }
    }

    if (y == nil) {
      @throw [ZXNotFoundException notFoundInstance];
    }
    return [self centerEdges:y z:z x:x t:t];
  }
   else {
    @throw [ZXNotFoundException notFoundInstance];
  }
}


/**
 * Ends up being a bit faster than Math.round(). This merely rounds its
 * argument to the nearest int, where x.5 rounds up.
 */
- (int) round:(float)d {
  return (int)(d + 0.5f);
}

- (ZXResultPoint *) getBlackPointOnSegment:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY {
  int dist = [self distanceL2:aX aY:aY bX:bX bY:bY];
  float xStep = (bX - aX) / dist;
  float yStep = (bY - aY) / dist;

  for (int i = 0; i < dist; i++) {
    int x = [self round:aX + i * xStep];
    int y = [self round:aY + i * yStep];
    if ([self.image get:x y:y]) {
      return [[[ZXResultPoint alloc] initWithX:x y:y] autorelease];
    }
  }

  return nil;
}

- (int) distanceL2:(float)aX aY:(float)aY bX:(float)bX bY:(float)bY {
  float xDiff = aX - bX;
  float yDiff = aY - bY;
  return [self round:(float)sqrt(xDiff * xDiff + yDiff * yDiff)];
}


/**
 * recenters the points of a constant distance towards the center
 * 
 * @param y bottom most point
 * @param z left most point
 * @param x right most point
 * @param t top most point
 * @return {@link ResultPoint}[] describing the corners of the rectangular
 * region. The first and last points are opposed on the diagonal, as
 * are the second and third. The first point will be the topmost
 * point and the last, the bottommost. The second point will be
 * leftmost and the third, the rightmost
 */
- (NSArray *) centerEdges:(ZXResultPoint *)y z:(ZXResultPoint *)z x:(ZXResultPoint *)x t:(ZXResultPoint *)t {
  float yi = [y x];
  float yj = [y y];
  float zi = [z x];
  float zj = [z y];
  float xi = [x x];
  float xj = [x y];
  float ti = [t x];
  float tj = [t y];
  if (yi < width / 2) {
    return [NSArray arrayWithObjects:[[[ZXResultPoint alloc] initWithX:ti - CORR y:tj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:zi + CORR y:zj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:xi - CORR y:xj - CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:yi + CORR y:yj - CORR] autorelease], nil];
  } else {
    return [NSArray arrayWithObjects:[[[ZXResultPoint alloc] initWithX:ti + CORR y:tj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:zi + CORR y:zj - CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:xi - CORR y:xj + CORR] autorelease],
            [[[ZXResultPoint alloc] initWithX:yi - CORR y:yj - CORR] autorelease], nil];
  }
}


/**
 * Determines whether a segment contains a black point
 * 
 * @param a          min value of the scanned coordinate
 * @param b          max value of the scanned coordinate
 * @param fixed      value of fixed coordinate
 * @param horizontal set to true if scan must be horizontal, false if vertical
 * @return true if a black point has been found, else false.
 */
- (BOOL) containsBlackPoint:(int)a b:(int)b fixed:(int)fixed horizontal:(BOOL)horizontal {
  if (horizontal) {

    for (int x = a; x <= b; x++) {
      if ([image get:x y:fixed]) {
        return YES;
      }
    }

  }
   else {

    for (int y = a; y <= b; y++) {
      if ([image get:fixed y:y]) {
        return YES;
      }
    }

  }
  return NO;
}

- (void) dealloc {
  [image release];
  [super dealloc];
}

@end
