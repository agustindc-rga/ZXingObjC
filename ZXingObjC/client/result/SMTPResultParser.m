#import "EmailAddressParsedResult.h"
#import "Result.h"
#import "SMTPResultParser.h"

@implementation SMTPResultParser

+ (EmailAddressParsedResult *) parse:(Result *)result {
  NSString * rawText = [result text];
  if (rawText == nil) {
    return nil;
  }
  if (!([rawText hasPrefix:@"smtp:"] || [rawText hasPrefix:@"SMTP:"])) {
    return nil;
  }
  NSString * emailAddress = [rawText substringFromIndex:5];
  NSString * subject = nil;
  NSString * body = nil;
  int colon = [emailAddress rangeOfString:@":"].location;
  if (colon >= 0) {
    subject = [emailAddress substringFromIndex:colon + 1];
    emailAddress = [emailAddress substringToIndex:colon];
    colon = [subject rangeOfString:@":"].location;
    if (colon >= 0) {
      body = [subject substringFromIndex:colon + 1];
      subject = [subject substringToIndex:colon];
    }
  }
  NSString * mailtoURI = [@"mailto:" stringByAppendingString:emailAddress];
  return [[[EmailAddressParsedResult alloc] init:emailAddress subject:subject body:body mailtoURI:mailtoURI] autorelease];
}

@end
