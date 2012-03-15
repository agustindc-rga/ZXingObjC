#import "ExpandedProductResultParser.h"

@implementation ExpandedProductResultParser

- (id) init {
  if (self = [super init]) {
  }
  return self;
}

+ (ExpandedProductParsedResult *) parse:(Result *)result {
  BarcodeFormat * format = [result barcodeFormat];
  if (![BarcodeFormat.RSS_EXPANDED isEqualTo:format]) {
    return nil;
  }
  NSString * rawText = [result text];
  if (rawText == nil) {
    return nil;
  }
  NSString * productID = @"-";
  NSString * sscc = @"-";
  NSString * lotNumber = @"-";
  NSString * productionDate = @"-";
  NSString * packagingDate = @"-";
  NSString * bestBeforeDate = @"-";
  NSString * expirationDate = @"-";
  NSString * weight = @"-";
  NSString * weightType = @"-";
  NSString * weightIncrement = @"-";
  NSString * price = @"-";
  NSString * priceIncrement = @"-";
  NSString * priceCurrency = @"-";
  NSMutableDictionary * uncommonAIs = [[[NSMutableDictionary alloc] init] autorelease];
  int i = 0;

  while (i < [rawText length]) {
    NSString * ai = [self findAIvalue:i rawText:rawText];
    if ([@"ERROR" isEqualToString:ai]) {
      return nil;
    }
    i += [ai length] + 2;
    NSString * value = [self findValue:i rawText:rawText];
    i += [value length];
    if ([@"00" isEqualToString:ai]) {
      sscc = value;
    }
     else if ([@"01" isEqualToString:ai]) {
      productID = value;
    }
     else if ([@"10" isEqualToString:ai]) {
      lotNumber = value;
    }
     else if ([@"11" isEqualToString:ai]) {
      productionDate = value;
    }
     else if ([@"13" isEqualToString:ai]) {
      packagingDate = value;
    }
     else if ([@"15" isEqualToString:ai]) {
      bestBeforeDate = value;
    }
     else if ([@"17" isEqualToString:ai]) {
      expirationDate = value;
    }
     else if ([@"3100" isEqualToString:ai] || [@"3101" isEqualToString:ai] || [@"3102" isEqualToString:ai] || [@"3103" isEqualToString:ai] || [@"3104" isEqualToString:ai] || [@"3105" isEqualToString:ai] || [@"3106" isEqualToString:ai] || [@"3107" isEqualToString:ai] || [@"3108" isEqualToString:ai] || [@"3109" isEqualToString:ai]) {
      weight = value;
      weightType = ExpandedProductParsedResult.KILOGRAM;
      weightIncrement = [ai substringFromIndex:3];
    }
     else if ([@"3200" isEqualToString:ai] || [@"3201" isEqualToString:ai] || [@"3202" isEqualToString:ai] || [@"3203" isEqualToString:ai] || [@"3204" isEqualToString:ai] || [@"3205" isEqualToString:ai] || [@"3206" isEqualToString:ai] || [@"3207" isEqualToString:ai] || [@"3208" isEqualToString:ai] || [@"3209" isEqualToString:ai]) {
      weight = value;
      weightType = ExpandedProductParsedResult.POUND;
      weightIncrement = [ai substringFromIndex:3];
    }
     else if ([@"3920" isEqualToString:ai] || [@"3921" isEqualToString:ai] || [@"3922" isEqualToString:ai] || [@"3923" isEqualToString:ai]) {
      price = value;
      priceIncrement = [ai substringFromIndex:3];
    }
     else if ([@"3930" isEqualToString:ai] || [@"3931" isEqualToString:ai] || [@"3932" isEqualToString:ai] || [@"3933" isEqualToString:ai]) {
      if ([value length] < 4) {
        return nil;
      }
      price = [value substringFromIndex:3];
      priceCurrency = [value substringFromIndex:0 param1:3];
      priceIncrement = [ai substringFromIndex:3];
    }
     else {
      [uncommonAIs setObject:ai param1:value];
    }
  }

  return [[[ExpandedProductParsedResult alloc] init:productID param1:sscc param2:lotNumber param3:productionDate param4:packagingDate param5:bestBeforeDate param6:expirationDate param7:weight param8:weightType param9:weightIncrement param10:price param11:priceIncrement param12:priceCurrency param13:uncommonAIs] autorelease];
}

+ (NSString *) findAIvalue:(int)i rawText:(NSString *)rawText {
  StringBuffer * buf = [[[StringBuffer alloc] init] autorelease];
  unichar c = [rawText characterAtIndex:i];
  if (c != '(') {
    return @"ERROR";
  }
  NSString * rawTextAux = [rawText substringFromIndex:i + 1];

  for (int index = 0; index < [rawTextAux length]; index++) {
    unichar currentChar = [rawTextAux characterAtIndex:index];

    switch (currentChar) {
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      [buf append:currentChar];
      break;
    case ')':
      return [buf description];
    default:
      return @"ERROR";
    }
  }

  return [buf description];
}

+ (NSString *) findValue:(int)i rawText:(NSString *)rawText {
  StringBuffer * buf = [[[StringBuffer alloc] init] autorelease];
  NSString * rawTextAux = [rawText substringFromIndex:i];

  for (int index = 0; index < [rawTextAux length]; index++) {
    unichar c = [rawTextAux characterAtIndex:index];
    if (c == '(') {
      if ([@"ERROR" isEqualToString:[self findAIvalue:index rawText:rawTextAux]]) {
        [buf append:'('];
      }
       else {
        break;
      }
    }
     else {
      [buf append:c];
    }
  }

  return [buf description];
}

@end
