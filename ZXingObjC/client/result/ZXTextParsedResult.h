#import "ZXParsedResult.h"

/**
 * A simple result type encapsulating a string that has no further
 * interpretation.
 * 
 * @author Sean Owen
 */

@interface ZXTextParsedResult : ZXParsedResult {
  NSString * text;
  NSString * language;
}

@property(nonatomic, retain, readonly) NSString * text;
@property(nonatomic, retain, readonly) NSString * language;
@property(nonatomic, retain, readonly) NSString * displayResult;

- (id) initWithText:(NSString *)text language:(NSString *)language;

@end
