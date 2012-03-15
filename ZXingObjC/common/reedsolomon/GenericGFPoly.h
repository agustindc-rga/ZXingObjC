/**
 * <p>Represents a polynomial whose coefficients are elements of a GF.
 * Instances of this class are immutable.</p>
 * 
 * <p>Much credit is due to William Rucklidge since portions of this code are an indirect
 * port of his C++ Reed-Solomon implementation.</p>
 * 
 * @author Sean Owen
 */

@class GenericGF;

@interface GenericGFPoly : NSObject {
  GenericGF * field;
  NSArray * coefficients;
}

- (id) init:(GenericGF *)field coefficients:(NSArray *)coefficients;
- (NSArray *) coefficients;
- (int) getDegree;
- (BOOL) isZero;
- (int) getCoefficient:(int)degree;
- (int) evaluateAt:(int)a;
- (GenericGFPoly *) addOrSubtract:(GenericGFPoly *)other;
- (GenericGFPoly *) multiply:(GenericGFPoly *)other;
- (GenericGFPoly *) multiplyScalar:(int)scalar;
- (GenericGFPoly *) multiplyByMonomial:(int)degree coefficient:(int)coefficient;
- (NSArray *) divide:(GenericGFPoly *)other;
- (NSString *) description;
@end
