#import "ZXByQuadrantReader.h"
#import "ZXNotFoundException.h"

@implementation ZXByQuadrantReader

- (id) initWithDelegate:(id<ZXReader>)aDelegate {
  if (self = [super init]) {
    delegate = aDelegate;
  }
  return self;
}

- (ZXResult *) decode:(ZXBinaryBitmap *)image {
  return [self decode:image hints:nil];
}

- (ZXResult *) decode:(ZXBinaryBitmap *)image hints:(NSMutableDictionary *)hints {
  int width = [image width];
  int height = [image height];
  int halfWidth = width / 2;
  int halfHeight = height / 2;

  ZXBinaryBitmap * topLeft = [image crop:0 top:0 width:halfWidth height:halfHeight];
  @try {
    return [delegate decode:topLeft hints:hints];
  }
  @catch (ZXNotFoundException * re) {
  }

  ZXBinaryBitmap * topRight = [image crop:halfWidth top:0 width:halfWidth height:halfHeight];
  @try {
    return [delegate decode:topRight hints:hints];
  }
  @catch (ZXNotFoundException * re) {
  }

  ZXBinaryBitmap * bottomLeft = [image crop:0 top:halfHeight width:halfWidth height:halfHeight];
  @try {
    return [delegate decode:bottomLeft hints:hints];
  }
  @catch (ZXNotFoundException * re) {
  }

  ZXBinaryBitmap * bottomRight = [image crop:halfWidth top:halfHeight width:halfWidth height:halfHeight];
  @try {
    return [delegate decode:bottomRight hints:hints];
  }
  @catch (ZXNotFoundException * re) {
  }

  int quarterWidth = halfWidth / 2;
  int quarterHeight = halfHeight / 2;
  ZXBinaryBitmap * center = [image crop:quarterWidth top:quarterHeight width:halfWidth height:halfHeight];
  return [delegate decode:center hints:hints];
}

- (void) reset {
  [delegate reset];
}

@end
