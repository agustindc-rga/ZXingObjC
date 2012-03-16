#import "ReedSolomonDecoder.h"
#import "GenericGF.h"
#import "ReedSolomonException.h"

@interface ReedSolomonDecoder ()

- (NSArray *) runEuclideanAlgorithm:(GenericGFPoly *)a b:(GenericGFPoly *)b R:(int)R;
- (NSArray *) findErrorLocations:(GenericGFPoly *)errorLocator;
- (NSArray *) findErrorMagnitudes:(GenericGFPoly *)errorEvaluator errorLocations:(NSArray *)errorLocations dataMatrix:(BOOL)dataMatrix;

@end

@implementation ReedSolomonDecoder

- (id) initWithField:(GenericGF *)aField {
  if (self = [super init]) {
    field = [aField retain];
  }
  return self;
}


/**
 * <p>Decodes given set of received codewords, which include both data and error-correction
 * codewords. Really, this means it uses Reed-Solomon to detect and correct errors, in-place,
 * in the input.</p>
 * 
 * @param received data and error-correction codewords
 * @param twoS number of error-correction codewords available
 * @throws ReedSolomonException if decoding fails for any reason
 */
- (void) decode:(NSMutableArray *)received twoS:(int)twoS {
  GenericGFPoly * poly = [[[GenericGFPoly alloc] initWithField:field coefficients:received] autorelease];
  NSMutableArray * syndromeCoefficients = [NSMutableArray arrayWithCapacity:twoS];
  for (int i = 0; i < twoS; i++) {
    [syndromeCoefficients addObject:[NSNull null]];
  }
  
  BOOL dataMatrix = [field isEqual:[GenericGF DataMatrixField256]];
  BOOL noError = YES;

  for (int i = 0; i < twoS; i++) {
    int eval = [poly evaluateAt:[field exp:dataMatrix ? i + 1 : i]];
    [syndromeCoefficients replaceObjectAtIndex:[syndromeCoefficients count] - 1 - i withObject:[NSNumber numberWithInt:eval]];
    if (eval != 0) {
      noError = NO;
    }
  }

  if (noError) {
    return;
  }
  GenericGFPoly * syndrome = [[[GenericGFPoly alloc] initWithField:field coefficients:syndromeCoefficients] autorelease];
  NSArray * sigmaOmega = [self runEuclideanAlgorithm:[field buildMonomial:twoS coefficient:1] b:syndrome R:twoS];
  GenericGFPoly * sigma = [sigmaOmega objectAtIndex:0];
  GenericGFPoly * omega = [sigmaOmega objectAtIndex:1];
  NSArray * errorLocations = [self findErrorLocations:sigma];
  NSArray * errorMagnitudes = [self findErrorMagnitudes:omega errorLocations:errorLocations dataMatrix:dataMatrix];

  for (int i = 0; i < [errorLocations count]; i++) {
    int position = [received count] - 1 - [field log:[[errorLocations objectAtIndex:i] intValue]];
    if (position < 0) {
      @throw [[[ReedSolomonException alloc] initWithName:@"ReedSolomonException"
                                                  reason:@"Bad error location"
                                                userInfo:nil] autorelease];
    }
    [received replaceObjectAtIndex:position withObject:[NSNumber numberWithInt:[GenericGF addOrSubtract:[[received objectAtIndex:position] intValue] b:[[errorMagnitudes objectAtIndex:i] intValue]]]];
  }
}

- (NSArray *) runEuclideanAlgorithm:(GenericGFPoly *)a b:(GenericGFPoly *)b R:(int)R {
  if ([a degree] < [b degree]) {
    GenericGFPoly * temp = a;
    a = b;
    b = temp;
  }
  GenericGFPoly * rLast = a;
  GenericGFPoly * r = b;
  GenericGFPoly * sLast = [field one];
  GenericGFPoly * s = [field zero];
  GenericGFPoly * tLast = [field zero];
  GenericGFPoly * t = [field one];

  while ([r degree] >= R / 2) {
    GenericGFPoly * rLastLast = rLast;
    GenericGFPoly * sLastLast = sLast;
    GenericGFPoly * tLastLast = tLast;
    rLast = r;
    sLast = s;
    tLast = t;
    if ([rLast zero]) {
      @throw [[[ReedSolomonException alloc] initWithName:@"ReedSolomonException"
                                                  reason:@"r_{i-1} was zero"
                                                userInfo:nil] autorelease];
    }
    r = rLastLast;
    GenericGFPoly * q = [field zero];
    int denominatorLeadingTerm = [rLast coefficient:[rLast degree]];
    int dltInverse = [field inverse:denominatorLeadingTerm];

    while ([r degree] >= [rLast degree] && ![r zero]) {
      int degreeDiff = [r degree] - [rLast degree];
      int scale = [field multiply:[r coefficient:[r degree]] b:dltInverse];
      q = [q addOrSubtract:[field buildMonomial:degreeDiff coefficient:scale]];
      r = [r addOrSubtract:[rLast multiplyByMonomial:degreeDiff coefficient:scale]];
    }

    s = [[q multiply:sLast] addOrSubtract:sLastLast];
    t = [[q multiply:tLast] addOrSubtract:tLastLast];
  }

  int sigmaTildeAtZero = [t coefficient:0];
  if (sigmaTildeAtZero == 0) {
    @throw [[[ReedSolomonException alloc] initWithName:@"ReedSolomonException"
                                                reason:@"sigmaTilde(0) was zero"
                                              userInfo:nil] autorelease];
  }
  int inverse = [field inverse:sigmaTildeAtZero];
  GenericGFPoly * sigma = [t multiplyScalar:inverse];
  GenericGFPoly * omega = [r multiplyScalar:inverse];
  return [NSArray arrayWithObjects:sigma, omega, nil];
}

- (NSArray *) findErrorLocations:(GenericGFPoly *)errorLocator {
  int numErrors = [errorLocator degree];
  if (numErrors == 1) {
    return [NSArray arrayWithObject:[NSNumber numberWithInt:[errorLocator coefficient:1]]];
  }
  NSMutableArray * result = [NSMutableArray arrayWithCapacity:numErrors];
  int e = 0;

  for (int i = 1; i < [field size] && e < numErrors; i++) {
    if ([errorLocator evaluateAt:i] == 0) {
      [result addObject:[NSNumber numberWithInt:[field inverse:i]]];
      e++;
    }
  }

  if (e != numErrors) {
    @throw [[[ReedSolomonException alloc] initWithName:@"ReedSolomonException"
                                                reason:@"Error locator degree does not match number of roots"
                                              userInfo:nil] autorelease];
  }
  return result;
}

- (NSArray *) findErrorMagnitudes:(GenericGFPoly *)errorEvaluator errorLocations:(NSArray *)errorLocations dataMatrix:(BOOL)dataMatrix {
  int s = [errorLocations count];
  NSMutableArray * result = [NSMutableArray array];

  for (int i = 0; i < s; i++) {
    int xiInverse = [field inverse:[[errorLocations objectAtIndex:i] intValue]];
    int denominator = 1;

    for (int j = 0; j < s; j++) {
      if (i != j) {
        int term = [field multiply:[[errorLocations objectAtIndex:j] intValue] b:xiInverse];
        int termPlus1 = (term & 0x1) == 0 ? term | 1 : term & ~1;
        denominator = [field multiply:denominator b:termPlus1];
      }
    }

    [result addObject:[NSNumber numberWithInt:[field multiply:[errorEvaluator evaluateAt:xiInverse] b:[field inverse:denominator]]]];
    if (dataMatrix) {
      [result replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:[field multiply:[[result objectAtIndex:i] intValue] b:xiInverse]]];
    }
  }

  return result;
}

- (void) dealloc {
  [field release];
  [super dealloc];
}

@end
