#import "BitArray.h"

@implementation BitArray

@synthesize size;
@synthesize sizeInBytes;
@synthesize bitArray;

- (id) init {
  if (self = [super init]) {
    size = 0;
    bits = [NSArray array];
  }
  return self;
}

- (id) initWithSize:(int)size {
  if (self = [super init]) {
    size = size;
    bits = [self makeArray:size];
  }
  return self;
}

- (int) sizeInBytes {
  return (size + 7) >> 3;
}

- (void) ensureCapacity:(int)size {
  if (size > bits.length << 5) {
    NSArray * newBits = [self makeArray:size];
    [System arraycopy:bits param1:0 param2:newBits param3:0 param4:bits.length];
    bits = newBits;
  }
}


/**
 * @param i bit to get
 * @return true iff bit i is set
 */
- (BOOL) get:(int)i {
  return (bits[i >> 5] & (1 << (i & 0x1F))) != 0;
}


/**
 * Sets bit i.
 * 
 * @param i bit to set
 */
- (void) set:(int)i {
  bits[i >> 5] |= 1 << (i & 0x1F);
}


/**
 * Flips bit i.
 * 
 * @param i bit to set
 */
- (void) flip:(int)i {
  bits[i >> 5] ^= 1 << (i & 0x1F);
}


/**
 * Sets a block of 32 bits, starting at bit i.
 * 
 * @param i first bit to set
 * @param newBits the new value of the next 32 bits. Note again that the least-significant bit
 * corresponds to bit i, the next-least-significant to i+1, and so on.
 */
- (void) setBulk:(int)i newBits:(int)newBits {
  bits[i >> 5] = newBits;
}


/**
 * Clears all bits (sets to false).
 */
- (void) clear {
  int max = bits.length;

  for (int i = 0; i < max; i++) {
    bits[i] = 0;
  }

}


/**
 * Efficient method to check if a range of bits is set, or not set.
 * 
 * @param start start of range, inclusive.
 * @param end end of range, exclusive
 * @param value if true, checks that bits in range are set, otherwise checks that they are not set
 * @return true iff all bits are set or not set in range, according to value argument
 * @throws IllegalArgumentException if end is less than or equal to start
 */
- (BOOL) isRange:(int)start end:(int)end value:(BOOL)value {
  if (end < start) {
    @throw [[[IllegalArgumentException alloc] init] autorelease];
  }
  if (end == start) {
    return YES;
  }
  end--;
  int firstInt = start >> 5;
  int lastInt = end >> 5;

  for (int i = firstInt; i <= lastInt; i++) {
    int firstBit = i > firstInt ? 0 : start & 0x1F;
    int lastBit = i < lastInt ? 31 : end & 0x1F;
    int mask;
    if (firstBit == 0 && lastBit == 31) {
      mask = -1;
    }
     else {
      mask = 0;

      for (int j = firstBit; j <= lastBit; j++) {
        mask |= 1 << j;
      }

    }
    if ((bits[i] & mask) != (value ? mask : 0)) {
      return NO;
    }
  }

  return YES;
}

- (void) appendBit:(BOOL)bit {
  [self ensureCapacity:size + 1];
  if (bit) {
    bits[size >> 5] |= (1 << (size & 0x1F));
  }
  size++;
}


/**
 * Appends the least-significant bits, from value, in order from most-significant to
 * least-significant. For example, appending 6 bits from 0x000001E will append the bits
 * 0, 1, 1, 1, 1, 0 in that order.
 */
- (void) appendBits:(int)value numBits:(int)numBits {
  if (numBits < 0 || numBits > 32) {
    @throw [[[IllegalArgumentException alloc] init:@"Num bits must be between 0 and 32"] autorelease];
  }
  [self ensureCapacity:size + numBits];

  for (int numBitsLeft = numBits; numBitsLeft > 0; numBitsLeft--) {
    [self appendBit:((value >> (numBitsLeft - 1)) & 0x01) == 1];
  }

}

- (void) appendBitArray:(BitArray *)other {
  int otherSize = [other size];
  [self ensureCapacity:size + otherSize];

  for (int i = 0; i < otherSize; i++) {
    [self appendBit:[other get:i]];
  }

}

- (void) xor:(BitArray *)other {
  if (bits.length != other.bits.length) {
    @throw [[[IllegalArgumentException alloc] init:@"Sizes don't match"] autorelease];
  }

  for (int i = 0; i < bits.length; i++) {
    bits[i] ^= other.bits[i];
  }

}


/**
 * 
 * @param bitOffset first bit to start writing
 * @param array array to write into. Bytes are written most-significant byte first. This is the opposite
 * of the internal representation, which is exposed by {@link #getBitArray()}
 * @param offset position in array to start writing
 * @param numBytes how many bytes to write
 */
- (void) toBytes:(int)bitOffset array:(NSArray *)array offset:(int)offset numBytes:(int)numBytes {

  for (int i = 0; i < numBytes; i++) {
    int theByte = 0;

    for (int j = 0; j < 8; j++) {
      if ([self get:bitOffset]) {
        theByte |= 1 << (7 - j);
      }
      bitOffset++;
    }

    array[offset + i] = (char)theByte;
  }

}


/**
 * Reverses all bits in the array.
 */
- (void) reverse {
  NSArray * newBits = [NSArray array];
  int size = size;

  for (int i = 0; i < size; i++) {
    if ([self get:size - i - 1]) {
      newBits[i >> 5] |= 1 << (i & 0x1F);
    }
  }

  bits = newBits;
}

+ (NSArray *) makeArray:(int)size {
  return [NSArray array];
}

- (NSString *) description {
  StringBuffer * result = [[[StringBuffer alloc] init:size] autorelease];

  for (int i = 0; i < size; i++) {
    if ((i & 0x07) == 0) {
      [result append:' '];
    }
    [result append:[self get:i] ? 'X' : '.'];
  }

  return [result description];
}

- (void) dealloc {
  [bits release];
  [super dealloc];
}

@end
