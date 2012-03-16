#import "BitArray.h"
#import "BitMatrix.h"

@implementation BitMatrix

@synthesize topLeftOnBit;
@synthesize bottomRightOnBit;
@synthesize width;
@synthesize height;

- (id) initWithDimension:(int)dimension {
  self = [self initWithWidth:dimension height:dimension];
  return self;
}

- (id) initWithWidth:(int)aWidth height:(int)aHeight {
  if (self = [super init]) {
    if (aWidth < 1 || aHeight < 1) {
      @throw [NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"Both dimensions must be greater than 0"
                                   userInfo:nil];
    }
    width = width;
    height = height;
    rowSize = (width + 31) >> 5;
    bits = (int*)malloc(rowSize * height * sizeof(int));
  }
  return self;
}


/**
 * <p>Gets the requested bit, where true means black.</p>
 * 
 * @param x The horizontal component (i.e. which column)
 * @param y The vertical component (i.e. which row)
 * @return value of given bit in matrix
 */
- (BOOL) get:(int)x y:(int)y {
  int offset = y * rowSize + (x >> 5);
  return ((bits[offset] >> (x & 0x1f)) & 1) != 0;
}


/**
 * <p>Sets the given bit to true.</p>
 * 
 * @param x The horizontal component (i.e. which column)
 * @param y The vertical component (i.e. which row)
 */
- (void) set:(int)x y:(int)y {
  int offset = y * rowSize + (x >> 5);
  bits[offset] |= 1 << (x & 0x1f);
}


/**
 * <p>Flips the given bit.</p>
 * 
 * @param x The horizontal component (i.e. which column)
 * @param y The vertical component (i.e. which row)
 */
- (void) flip:(int)x y:(int)y {
  int offset = y * rowSize + (x >> 5);
  bits[offset] ^= 1 << (x & 0x1f);
}


/**
 * Clears all bits (sets to false).
 */
- (void) clear {
  int max = sizeof(bits) / sizeof(int);

  for (int i = 0; i < max; i++) {
    bits[i] = 0;
  }

}


/**
 * <p>Sets a square region of the bit matrix to true.</p>
 * 
 * @param left The horizontal position to begin at (inclusive)
 * @param top The vertical position to begin at (inclusive)
 * @param width The width of the region
 * @param height The height of the region
 */
- (void) setRegion:(int)left top:(int)top width:(int)aWidth height:(int)aHeight {
  if (top < 0 || left < 0) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Left and top must be nonnegative"
                                 userInfo:nil];
  }
  if (aHeight < 1 || aWidth < 1) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Height and width must be at least 1"
                                 userInfo:nil];
  }
  int right = left + width;
  int bottom = top + height;
  if (bottom > aHeight || right > aWidth) {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"The region must fit inside the matrix"
                                 userInfo:nil];
  }
  for (int y = top; y < bottom; y++) {
    int offset = y * rowSize;
    for (int x = left; x < right; x++) {
      bits[offset + (x >> 5)] |= 1 << (x & 0x1f);
    }
  }
}


/**
 * A fast method to retrieve one row of data from the matrix as a BitArray.
 * 
 * @param y The row to retrieve
 * @param row An optional caller-allocated BitArray, will be allocated if null or too small
 * @return The resulting BitArray - this reference should always be used even when passing
 * your own row
 */
- (BitArray *) getRow:(int)y row:(BitArray *)row {
  if (row == nil || [row size] < width) {
    row = [[[BitArray alloc] initWithSize:width] autorelease];
  }
  int offset = y * rowSize;
  for (int x = 0; x < rowSize; x++) {
    [row setBulk:x << 5 newBits:bits[offset + x]];
  }

  return row;
}


/**
 * This is useful in detecting a corner of a 'pure' barcode.
 * 
 * @return {x,y} coordinate of top-left-most 1 bit, or null if it is all white
 */
- (NSArray *) topLeftOnBit {
  int bitsOffset = 0;
  while (bitsOffset < sizeof(bits) / sizeof(int) && bits[bitsOffset] == 0) {
    bitsOffset++;
  }
  if (bitsOffset == sizeof(bits) / sizeof(int)) {
    return nil;
  }
  int y = bitsOffset / rowSize;
  int x = (bitsOffset % rowSize) << 5;

  int theBits = bits[bitsOffset];
  int bit = 0;
  while ((theBits << (31 - bit)) == 0) {
    bit++;
  }
  x += bit;
  return [NSArray arrayWithObjects:[NSNumber numberWithInt:x], [NSNumber numberWithInt:y], nil];
}

- (NSArray *) bottomRightOnBit {
  int bitsOffset = (sizeof(bits) / sizeof(int)) - 1;
  while (bitsOffset >= 0 && bits[bitsOffset] == 0) {
    bitsOffset--;
  }
  if (bitsOffset < 0) {
    return nil;
  }

  int y = bitsOffset / rowSize;
  int x = (bitsOffset % rowSize) << 5;

  int theBits = bits[bitsOffset];
  int bit = 31;
  while ((theBits >> bit) == 0) {
    bit--;
  }
  x += bit;

  return [NSArray arrayWithObjects:[NSNumber numberWithInt:x], [NSNumber numberWithInt:y], nil];
}

- (BOOL) isEqualTo:(NSObject *)o {
  if (!([o isKindOfClass:[BitMatrix class]])) {
    return NO;
  }
  BitMatrix * other = (BitMatrix *)o;
  if (width != other.width || height != other.height || rowSize != other->rowSize || sizeof(bits) != sizeof(other->bits)) {
    return NO;
  }
  for (int i = 0; i < sizeof(bits) / sizeof(int); i++) {
    if (bits[i] != other->bits[i]) {
      return NO;
    }
  }
  return YES;
}

- (NSUInteger) hash {
  int hash = width;
  hash = 31 * hash + width;
  hash = 31 * hash + height;
  hash = 31 * hash + rowSize;
  for (int i = 0; i < sizeof(bits) / sizeof(int); i++) {
    hash = 31 * hash + bits[i];
  }
  return hash;
}

- (NSString *) description {
  NSMutableString * result = [NSMutableString stringWithCapacity:height * (width + 1)];
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      [result appendString:[self get:x y:y] ? @"X " : @"  "];
    }
    [result appendString:@"\n"];
  }
  return result;
}

- (void) dealloc {
  free(bits);
  [super dealloc];
}

@end
