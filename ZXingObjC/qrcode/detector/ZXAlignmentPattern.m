#import "ZXAlignmentPattern.h"

@implementation ZXAlignmentPattern

- (id) initWithPosX:(float)posX posY:(float)posY estimatedModuleSize:(float)anEstimatedModuleSize {
  if (self = [super initWithX:posX y:posY]) {
    estimatedModuleSize = anEstimatedModuleSize;
  }
  return self;
}


/**
 * <p>Determines if this alignment pattern "about equals" an alignment pattern at the stated
 * position and size -- meaning, it is at nearly the same center with nearly the same size.</p>
 */
- (BOOL) aboutEquals:(float)moduleSize i:(float)i j:(float)j {
  if (fabsf(i - y) <= moduleSize && fabsf(j - x) <= moduleSize) {
    float moduleSizeDiff = fabsf(moduleSize - estimatedModuleSize);
    return moduleSizeDiff <= 1.0f || moduleSizeDiff / estimatedModuleSize <= 1.0f;
  }
  return NO;
}

@end
